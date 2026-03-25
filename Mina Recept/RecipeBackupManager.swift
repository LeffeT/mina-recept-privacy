//
//  RecipeBackupManager.swift
//  Mina Recept
//
//  Created by OpenAI Codex on 2026-03-25.
//

import Combine
import CoreData
import Foundation
import os

@MainActor
final class RecipeBackupManager: ObservableObject {
    private let container: NSPersistentCloudKitContainer
    private var cancellables = Set<AnyCancellable>()
    private var backupTask: Task<Void, Never>?

    init(container: NSPersistentCloudKitContainer) {
        self.container = container
        observeContextSaves()
    }

    deinit {
        backupTask?.cancel()
    }

    func refreshBackup() {
        scheduleBackup()
        mirrorImagesLocally()
    }

    func handleCloudStateChange(
        _ state: CloudSyncStatus.State,
        locale: Locale
    ) {
        switch state {
        case .unavailable:
            restoreFromLocalBackupIfNeeded(locale: locale)
        case .idle:
            deduplicateRecipesIfNeeded()
            scheduleBackup()
            mirrorImagesLocally()
        case .syncing, .error:
            break
        }
    }

    private func observeContextSaves() {
        let coordinator = container.persistentStoreCoordinator
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave)
            .compactMap { $0.object as? NSManagedObjectContext }
            .filter { context in
                return context.persistentStoreCoordinator === coordinator
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.scheduleBackup()
            }
            .store(in: &cancellables)
    }

    private func scheduleBackup() {
        backupTask?.cancel()
        backupTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self?.writeLocalBackup()
        }
    }

    private func writeLocalBackup() {
        guard let backupURL else { return }

        let context = container.viewContext
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let recipes = (try? context.fetch(request)) ?? []

        var didAssignIDs = false
        let snapshotRecipes = recipes.map { recipe -> LocalRecipeBackupRecipe in
            let identifier: UUID
            if let existingID = recipe.id {
                identifier = existingID
            } else {
                let newID = UUID()
                recipe.id = newID
                identifier = newID
                didAssignIDs = true
            }

            if let filename = recipe.imageFilename {
                FileHelper.ensureLocalImageAvailability(filename: filename)
            }

            return LocalRecipeBackupRecipe(
                id: identifier.uuidString,
                title: recipe.title ?? "",
                instructions: recipe.instructions ?? "",
                imageFilename: recipe.imageFilename,
                date: recipe.date,
                baseServings: max(1, Int(recipe.baseServings)),
                group1Title: recipe.group1Title,
                group2Title: recipe.group2Title,
                group3Title: recipe.group3Title,
                ingredients: recipe.ingredientArray.map {
                    PendingIngredient(
                        name: $0.safeName,
                        amount: $0.safeAmount,
                        amountText: $0.amountText,
                        unit: $0.safeUnit,
                        groupIndex: $0.safeGroupIndex
                    )
                }
            )
        }

        if didAssignIDs {
            try? context.save()
        }

        let snapshot = LocalRecipeBackupSnapshot(
            version: 1,
            recipes: snapshotRecipes
        )

        do {
            try ensureBackupDirectory()
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: backupURL, options: .atomic)
            AppLog.storage.debug(
                "Local recipe backup updated: \(snapshotRecipes.count, privacy: .public)"
            )
        } catch {
            AppLog.storage.error(
                "Could not write local recipe backup: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func restoreFromLocalBackupIfNeeded(locale: Locale) {
        let context = container.viewContext
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let currentCount = (try? context.count(for: request)) ?? 0
        guard currentCount == 0 else { return }

        guard
            let backupURL,
            let data = try? Data(contentsOf: backupURL),
            let snapshot = try? JSONDecoder().decode(
                LocalRecipeBackupSnapshot.self,
                from: data
            ),
            !snapshot.recipes.isEmpty
        else {
            return
        }

        for item in snapshot.recipes {
            let recipe = Recipe(context: context)
            recipe.id = UUID(uuidString: item.id) ?? UUID()
            recipe.title = item.title
            recipe.sortTitle = item.title.sortKey(locale: locale)
            recipe.instructions = item.instructions
            recipe.imageFilename = item.imageFilename
            recipe.date = item.date ?? Date()
            recipe.baseServings = Int16(max(1, item.baseServings))
            recipe.group1Title = item.group1Title
            recipe.group2Title = item.group2Title
            recipe.group3Title = item.group3Title

            if let filename = item.imageFilename {
                FileHelper.ensureLocalImageAvailability(filename: filename)
            }

            for ingredientItem in item.ingredients {
                let ingredient = IngredientEntity(context: context)
                ingredient.id = UUID()
                ingredient.name = ingredientItem.name
                ingredient.amount = ingredientItem.amount
                ingredient.amountText = ingredientItem.amountText
                ingredient.unit = ingredientItem.unit
                ingredient.groupIndex = Int16(ingredientItem.groupIndex)
                ingredient.recipe = recipe
            }
        }

        do {
            try context.save()
            AppLog.storage.info(
                "Restored recipes from local backup: \(snapshot.recipes.count, privacy: .public)"
            )
        } catch {
            AppLog.storage.error(
                "Could not restore local recipe backup: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func deduplicateRecipesIfNeeded() {
        let context = container.viewContext
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let recipes = (try? context.fetch(request)) ?? []

        let grouped = Dictionary(grouping: recipes) { recipe in
            recipe.id?.uuidString ?? recipe.objectID.uriRepresentation().absoluteString
        }

        var didChange = false

        for (_, group) in grouped where group.count > 1 {
            guard let preferred = group.max(by: { recipeScore($0) < recipeScore($1) }) else {
                continue
            }

            for duplicate in group where duplicate.objectID != preferred.objectID {
                merge(recipe: duplicate, into: preferred)
                context.delete(duplicate)
                didChange = true
            }
        }

        if didChange {
            try? context.save()
            AppLog.storage.debug("Duplicate recipes merged after backup restore")
        }
    }

    private func mirrorImagesLocally() {
        let context = container.viewContext
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let recipes = (try? context.fetch(request)) ?? []

        let filenames: Set<String> = Set(
            recipes.compactMap { recipe in
                guard let filename = recipe.imageFilename, !filename.isEmpty else {
                    return nil
                }
                return filename
            }
        )

        for filename in filenames {
            FileHelper.mirrorImageLocallyIfNeeded(filename: filename)
        }
    }

    private func merge(recipe source: Recipe, into target: Recipe) {
        if (target.title ?? "").isEmpty {
            target.title = source.title
        }
        if (target.sortTitle ?? "").isEmpty {
            target.sortTitle = source.sortTitle
        }
        if (target.instructions ?? "").isEmpty {
            target.instructions = source.instructions
        }
        if target.imageFilename == nil {
            target.imageFilename = source.imageFilename
        }
        if target.date == nil {
            target.date = source.date
        }
        if target.baseServings == 0 {
            target.baseServings = source.baseServings
        }
        if target.group1Title == nil {
            target.group1Title = source.group1Title
        }
        if target.group2Title == nil {
            target.group2Title = source.group2Title
        }
        if target.group3Title == nil {
            target.group3Title = source.group3Title
        }

        let targetIngredients = (target.ingredients as? Set<IngredientEntity>) ?? []
        let sourceIngredients = (source.ingredients as? Set<IngredientEntity>) ?? []
        if targetIngredients.isEmpty && !sourceIngredients.isEmpty {
            for ingredient in sourceIngredients {
                ingredient.recipe = target
            }
        }
    }

    private func recipeScore(_ recipe: Recipe) -> Int {
        let ingredientCount = (recipe.ingredients as? Set<IngredientEntity>)?.count ?? 0
        let titleScore = (recipe.title ?? "").isEmpty ? 0 : 4
        let instructionsScore = (recipe.instructions ?? "").isEmpty ? 0 : 3
        let imageScore = recipe.imageFilename == nil ? 0 : 2
        let servingsScore = recipe.baseServings > 0 ? 1 : 0
        return ingredientCount * 10 + titleScore + instructionsScore + imageScore + servingsScore
    }

    private var backupURL: URL? {
        guard let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first else {
            return nil
        }

        return base
            .appendingPathComponent("RecipeBackup", isDirectory: true)
            .appendingPathComponent("recipes.json")
    }

    private func ensureBackupDirectory() throws {
        guard let directory = backupURL?.deletingLastPathComponent() else { return }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }
}

private struct LocalRecipeBackupSnapshot: Codable {
    let version: Int
    let recipes: [LocalRecipeBackupRecipe]
}

private struct LocalRecipeBackupRecipe: Codable {
    let id: String
    let title: String
    let instructions: String
    let imageFilename: String?
    let date: Date?
    let baseServings: Int
    let group1Title: String?
    let group2Title: String?
    let group3Title: String?
    let ingredients: [PendingIngredient]
}
