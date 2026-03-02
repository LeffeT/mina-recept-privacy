//
//  DemoRecipeSeeder.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-27.
//

import CoreData
import Foundation
import os
import UIKit

enum DemoRecipeSeeder {
    private static let didSeedKey = "did_seed_demo_recipe_v1"
    private static let demoRecipeIDKey = "demo_recipe_id"
    private static let demoLanguageKey = "demo_recipe_language"
    private static let demoImageName = "demo_pancakes"

    static func seedIfNeeded(
        context: NSManagedObjectContext,
        languageManager: LanguageManager
    ) {
        let defaults = UserDefaults.standard
        let desiredLanguage = resolvedLanguage(from: languageManager)
        let didSeed = defaults.bool(forKey: didSeedKey)
        let demoIDString = defaults.string(forKey: demoRecipeIDKey)
        let currentLangRaw = defaults.string(forKey: demoLanguageKey)
        let currentLang = AppLanguage(rawValue: currentLangRaw ?? "") ?? desiredLanguage

        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.includesPendingChanges = true

        let count = (try? context.count(for: request)) ?? 0
        if !didSeed {
            if count > 0 {
                defaults.set(true, forKey: didSeedKey)
                return
            }
            createDemo(
                in: context,
                languageManager: languageManager,
                language: desiredLanguage
            )
            return
        }

        guard let demoIDString else { return }
        guard let demoID = UUID(uuidString: demoIDString) else {
            defaults.removeObject(forKey: demoRecipeIDKey)
            defaults.removeObject(forKey: demoLanguageKey)
            return
        }

        if let demoRecipe = fetchRecipe(id: demoID, context: context) {
            if currentLang != desiredLanguage {
                context.delete(demoRecipe)
                createDemo(
                    in: context,
                    languageManager: languageManager,
                    language: desiredLanguage
                )
            } else {
                attachImageIfNeeded(to: demoRecipe, context: context)
            }
        } else {
            defaults.removeObject(forKey: demoRecipeIDKey)
            defaults.removeObject(forKey: demoLanguageKey)
        }
    }

    private static func demoData(
        for language: AppLanguage
    ) -> DemoRecipeData {
        switch language {
        case .swedish:
            return DemoRecipeData(
                title: "Pannkakor",
                servings: 4,
                instructions: """
1. Vispa ihop mjöl, socker och salt.
2. Häll i hälften av mjölken och vispa slätt.
3. Tillsätt resten av mjölken och äggen.
4. Smält smöret och blanda ner.
5. Stek tunna pannkakor i smör.
""",
                ingredients: [
                    DemoIngredient(name: "Vetemjöl", amountText: "2,5", unit: "dl"),
                    DemoIngredient(name: "Mjölk", amountText: "5", unit: "dl"),
                    DemoIngredient(name: "Ägg", amountText: "2", unit: "pcs"),
                    DemoIngredient(name: "Smör", amountText: "2", unit: "tbsp"),
                    DemoIngredient(name: "Salt", amountText: "1", unit: "pinch")
                ]
            )
        case .english:
            return DemoRecipeData(
                title: "Pancakes",
                servings: 4,
                instructions: """
1. Mix flour, sugar and salt.
2. Whisk in half of the milk until smooth.
3. Add the rest of the milk and the eggs.
4. Melt the butter and stir in.
5. Fry thin pancakes in butter.
""",
                ingredients: [
                    DemoIngredient(name: "Flour", amountText: "2.5", unit: "dl"),
                    DemoIngredient(name: "Milk", amountText: "5", unit: "dl"),
                    DemoIngredient(name: "Eggs", amountText: "2", unit: "pcs"),
                    DemoIngredient(name: "Butter", amountText: "2", unit: "tbsp"),
                    DemoIngredient(name: "Salt", amountText: "1", unit: "pinch")
                ]
            )
        case .system:
            return DemoRecipeData(title: "", servings: 0, instructions: "", ingredients: [])
        }
    }

    private static func resolvedLanguage(
        from languageManager: LanguageManager
    ) -> AppLanguage {
        switch languageManager.selectedLanguage {
        case .system:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            return code == "sv" ? .swedish : .english
        case .swedish, .english:
            return languageManager.selectedLanguage
        }
    }

    private static func fetchRecipe(
        id: UUID,
        context: NSManagedObjectContext
    ) -> Recipe? {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    private static func createDemo(
        in context: NSManagedObjectContext,
        languageManager: LanguageManager,
        language: AppLanguage
    ) {
        let demo = demoData(for: language)

        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = demo.title
        recipe.sortTitle = demo.title.sortKey(locale: languageManager.locale)
        recipe.instructions = demo.instructions
        recipe.date = Date()
        recipe.baseServings = Int16(demo.servings)
        recipe.group1Title = L("ingredients", languageManager)
        recipe.group2Title = nil
        recipe.group3Title = nil

        recipe.imageFilename = saveDemoImageIfAvailable()

        for item in demo.ingredients {
            let ingredient = IngredientEntity(context: context)
            ingredient.id = UUID()
            ingredient.name = item.name
            ingredient.unit = item.unit
            ingredient.amountText = item.amountText
            ingredient.amount = IngredientFormatter.parseAmount(
                item.amountText,
                locale: languageManager.locale
            ) ?? 0
            ingredient.scalable = true
            ingredient.pluralName = nil
            ingredient.groupIndex = 0
            ingredient.recipe = recipe
        }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: didSeedKey)
            UserDefaults.standard.set(recipe.id?.uuidString, forKey: demoRecipeIDKey)
            UserDefaults.standard.set(language.rawValue, forKey: demoLanguageKey)
            AppLog.storage.debug("Demo-recept skapat")
        } catch {
            AppLog.storage.error(
                "Kunde inte spara demo-recept: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private static func attachImageIfNeeded(
        to recipe: Recipe,
        context: NSManagedObjectContext
    ) {
        guard recipe.imageFilename?.isEmpty ?? true else { return }
        guard let filename = saveDemoImageIfAvailable() else { return }
        recipe.imageFilename = filename
        try? context.save()
    }

    private static func saveDemoImageIfAvailable() -> String? {
        guard let image = UIImage(named: demoImageName) else {
            AppLog.storage.debug("Demo-bild saknas i Assets: \(demoImageName, privacy: .public)")
            return nil
        }

        let resized = image.normalizedAndResized(maxWidth: 1200, maxHeight: 800)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return nil }

        let filename = "demo-\(UUID().uuidString).jpg"
        FileHelper.saveImageData(filename: filename, data: data)
        return filename
    }
}

private struct DemoRecipeData {
    let title: String
    let servings: Int
    let instructions: String
    let ingredients: [DemoIngredient]
}

private struct DemoIngredient {
    let name: String
    let amountText: String
    let unit: String
}
