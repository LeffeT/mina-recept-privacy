//
//  ImportPayloadHandler.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-09.
//


import Foundation
import CoreData
import os

enum ImportPayloadHandler {
    private static var inProgress = Set<String>() 

    // MARK: - Logger
    private static let logger = Logger(
        subsystem: "com.se.leiftarvainen.minareceipt",
        category: "import"
    )

    // MARK: - Core import från payload
    private static func importFromPayload(
        _ payload: PendingRecipePayload,
        recipeID: String,
        context: NSManagedObjectContext,
        onSuccess: @escaping () -> Void
    ) {
        logger.info("📦 Importerar payload id: \(payload.id)")

        // 3 Skapa Recipe
        let recipe = Recipe(context: context)
        recipe.id = UUID(uuidString: payload.id) ?? UUID()

        let finalTitle = payload.title.isEmpty ? "Nytt recept" : payload.title
        recipe.title = finalTitle
        recipe.sortTitle = finalTitle.sortKey(locale: LanguageManager.shared.locale)
        recipe.instructions = payload.instructions
        recipe.date = Date()
        recipe.imageFilename = payload.imageFilename
        recipe.baseServings = Int16(max(1, payload.baseServings))
        if let titles = payload.groupTitles {
            recipe.group1Title = titles.indices.contains(0) ? titles[0] : nil
            recipe.group2Title = titles.indices.contains(1) ? titles[1] : nil
            recipe.group3Title = titles.indices.contains(2) ? titles[2] : nil
        }

        // 4 Ingredienser
        for item in payload.ingredients {
            let ingredient = IngredientEntity(context: context)
            ingredient.id = UUID()
            ingredient.name = item.name
            ingredient.amount = item.amount
            ingredient.amountText = item.amountText
            ingredient.unit = item.unit
            ingredient.groupIndex = Int16(item.groupIndex)
            ingredient.recipe = recipe
        }

        // 5 Spara
        do {
            try context.save()

            // Rensa payload (både lokalt + iCloud)
            PendingRecipePayloadStore.clear(id: recipeID)
            iCloudPayloadStore.clear(id: recipeID)
            CloudKitService.shared.deletePublicRecipe(id: recipeID)

            DispatchQueue.main.async {
                onSuccess()
            }

            logger.info("✅ Import klar för recipeID: \(recipeID)")
        } catch {
            logger.error("❌ Import failed – \(error.localizedDescription)")
        }
    }

    // MARK: - Publik entry point
    static func importPendingRecipe(
        recipeID: String,
        onSuccess: @escaping () -> Void,
        onAlreadyImported: @escaping () -> Void,
        onMissingPayload: @escaping () -> Void,
        onExpired: @escaping () -> Void
    ) {
        logger.info("📥 Import start – recipeID: \(recipeID)")

        guard !inProgress.contains(recipeID) else {
            logger.info("⏳ Import already in progress – \(recipeID)")
            DispatchQueue.main.async {
                onAlreadyImported()
            }
            return
        }

        inProgress.insert(recipeID)
        let context = CoreDataStack.shared.viewContext

        // 1️⃣ Finns receptet redan lokalt?
        if recipeExists(id: recipeID, context: context) {
            logger.info("⚠️ Recipe already imported – \(recipeID)")
            inProgress.remove(recipeID)
            DispatchQueue.main.async {
                onAlreadyImported()
            }
            return
        }

        // 2️⃣ Finns payload lokalt?
        if let payload = PendingRecipePayloadStore.load(id: recipeID) {
            logger.info("📦 Payload hittad lokalt")
            importFromPayload(
                payload,
                recipeID: recipeID,
                context: context,
                onSuccess: {
                    inProgress.remove(recipeID)
                    DispatchQueue.main.async {
                        onSuccess()
                    }
                }
            )
            return
        }

        // 3️⃣ Finns payload i iCloud?
        if let payload = iCloudPayloadStore.load(id: recipeID) {
            logger.info("☁️ Payload laddad från iCloud")
            importFromPayload(
                payload,
                recipeID: recipeID,
                context: context,
                onSuccess: {
                    inProgress.remove(recipeID)
                    DispatchQueue.main.async {
                        onSuccess()
                    }
                }
            )
            return
        }

        // 4️⃣ Finns payload i CloudKit?
        CloudKitService.shared.fetchPublicRecipe(id: recipeID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let payload):
                    self.logger.info("☁️ Payload laddad från CloudKit")
                    importFromPayload(
                        payload,
                        recipeID: recipeID,
                        context: context,
                        onSuccess: {
                            inProgress.remove(recipeID)
                            DispatchQueue.main.async {
                                onSuccess()
                            }
                        }
                    )
                case .expired:
                    self.logger.error("⏰ Payload expired for recipeID: \(recipeID)")
                    inProgress.remove(recipeID)
                    DispatchQueue.main.async {
                        onExpired()
                    }
                case .notFound, .failure:
                    // ❌ 5️⃣ Payload saknas = FEL, inte "redan importerat"
                    self.logger.error("❌ Payload saknas helt för recipeID: \(recipeID)")
                    inProgress.remove(recipeID)
                    DispatchQueue.main.async {
                        onMissingPayload()
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private static func recipeExists(
        id: String,
        context: NSManagedObjectContext
    ) -> Bool {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        return (try? context.count(for: request)) ?? 0 > 0
    }
}
