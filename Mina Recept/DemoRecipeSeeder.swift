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
    private static let groupedDemoRecipeIDKey = "grouped_demo_recipe_id"
    private static let demoLanguageKey = "demo_recipe_language"
    private static let demoSeedVersionKey = "demo_seed_version"
    private static let currentDemoSeedVersion = 4

    static func seedIfNeeded(
        container: NSPersistentContainer,
        languageManager: LanguageManager
    ) {
        let selectedLanguage = languageManager.selectedLanguage
        let locale = languageManager.locale
        let context = container.newBackgroundContext()

        context.perform {
            seedIfNeeded(
                context: context,
                selectedLanguage: selectedLanguage,
                locale: locale
            )
        }
    }

    private static func seedIfNeeded(
        context: NSManagedObjectContext,
        selectedLanguage: AppLanguage,
        locale: Locale
    ) {
        let defaults = UserDefaults.standard
        let desiredLanguage = resolvedLanguage(from: selectedLanguage)
        let didSeed = defaults.bool(forKey: didSeedKey)
        let seededVersion = defaults.integer(forKey: demoSeedVersionKey)
        let currentLangRaw = defaults.string(forKey: demoLanguageKey)
        let currentLang = AppLanguage(rawValue: currentLangRaw ?? "") ?? desiredLanguage
        let requiresRecipeRefresh = seededVersion < currentDemoSeedVersion

        var primaryDemoID = validDemoID(
            from: defaults.string(forKey: demoRecipeIDKey),
            key: demoRecipeIDKey,
            defaults: defaults
        )
        var groupedDemoID = validDemoID(
            from: defaults.string(forKey: groupedDemoRecipeIDKey),
            key: groupedDemoRecipeIDKey,
            defaults: defaults
        )

        // If a tracked demo recipe was manually deleted, stop tracking it.
        primaryDemoID = removeTrackingIfRecipeMissing(
            id: primaryDemoID,
            key: demoRecipeIDKey,
            context: context,
            defaults: defaults
        )
        groupedDemoID = removeTrackingIfRecipeMissing(
            id: groupedDemoID,
            key: groupedDemoRecipeIDKey,
            context: context,
            defaults: defaults
        )

        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.includesPendingChanges = true

        let count = (try? context.count(for: request)) ?? 0
        if !didSeed {
            if count > 0 {
                defaults.set(true, forKey: didSeedKey)
                defaults.set(currentDemoSeedVersion, forKey: demoSeedVersionKey)
                return
            }
            let demos = demoRecipes(for: desiredLanguage)
            primaryDemoID = createDemo(
                in: context,
                locale: locale,
                language: desiredLanguage,
                data: demos.primary
            )
            groupedDemoID = createDemo(
                in: context,
                locale: locale,
                language: desiredLanguage,
                data: demos.grouped
            )
            persistDemoState(
                defaults: defaults,
                language: desiredLanguage,
                primaryDemoID: primaryDemoID,
                groupedDemoID: groupedDemoID
            )
            return
        }

        // Existing users with their own recipes should not suddenly get demo recipes.
        guard primaryDemoID != nil || groupedDemoID != nil else {
            return
        }

        let demos = demoRecipes(for: desiredLanguage)

        if currentLang != desiredLanguage || requiresRecipeRefresh {
            if primaryDemoID != nil {
                deleteDemoRecipeIfExists(id: primaryDemoID, context: context)
                primaryDemoID = createDemo(
                    in: context,
                    locale: locale,
                    language: desiredLanguage,
                    data: demos.primary
                )
            }

            if groupedDemoID != nil {
                deleteDemoRecipeIfExists(id: groupedDemoID, context: context)
                groupedDemoID = createDemo(
                    in: context,
                    locale: locale,
                    language: desiredLanguage,
                    data: demos.grouped
                )
            }

            persistDemoState(
                defaults: defaults,
                language: desiredLanguage,
                primaryDemoID: primaryDemoID,
                groupedDemoID: groupedDemoID
            )
            return
        }

        if let id = primaryDemoID,
           let demoRecipe = fetchRecipe(id: id, context: context) {
            attachImageIfNeeded(
                to: demoRecipe,
                imageName: demos.primary.imageAssetName,
                context: context
            )
        } else if primaryDemoID != nil {
            primaryDemoID = nil
        }

        if let id = groupedDemoID,
           let groupedDemo = fetchRecipe(id: id, context: context) {
            attachImageIfNeeded(
                to: groupedDemo,
                imageName: demos.grouped.imageAssetName,
                context: context
            )
        } else if groupedDemoID != nil {
            groupedDemoID = nil
        }

        persistDemoState(
            defaults: defaults,
            language: desiredLanguage,
            primaryDemoID: primaryDemoID,
            groupedDemoID: groupedDemoID
        )
    }

    private static func demoRecipes(
        for language: AppLanguage
    ) -> (primary: DemoRecipeData, grouped: DemoRecipeData) {
        switch language {
        case .swedish:
            let primary = DemoRecipeData(
                title: "Pannkakor (demo)",
                servings: 4,
                imageAssetName: "demo_pancakes",
                instructions: """
1. Vispa ihop mjöl, socker och salt.
2. Häll i hälften av mjölken och vispa slätt.
3. Tillsätt resten av mjölken och äggen.
4. Smält smöret och blanda ner.
5. Stek tunna pannkakor i smör.
""",
                groupTitles: [
                    localized("ingredients", language: .swedish),
                    nil,
                    nil
                ],
                ingredients: [
                    DemoIngredient(name: "Vetemjöl", amountText: "2,5", unit: "dl"),
                    DemoIngredient(name: "Mjölk", amountText: "5", unit: "dl"),
                    DemoIngredient(name: "Ägg", amountText: "2", unit: "pcs"),
                    DemoIngredient(name: "Smör", amountText: "2", unit: "tbsp"),
                    DemoIngredient(name: "Salt", amountText: "1", unit: "pinch")
                ]
            )

            let grouped = DemoRecipeData(
                title: "Kyckling tikka masala (demo)",
                servings: 4,
                imageAssetName: "tikka_masala",
                instructions: """
Marinerad Kyckling

1. Blanda ingredienserna i en skål.
Skär kycklingen i bitar, lägg i kycklingen och låt stå 15 minuter.

Tikka Masala Sås

2. Fräs lök, vitlök och ingefära till såsen i lite olja.

3. Tillsätt hackad koriander och krossade tomater, låt småkoka i 15 minuter.

4. Stek kycklingen med marinaden och blanda ner i såsen.

Servering

5. Krydda med salt och svartpeppar, toppa med koriander.
Servera med ris.
""",
                groupTitles: [
                    "Marinerad kyckling",
                    "Tikka masala-sås",
                    "Servering"
                ],
                ingredients: [
                    DemoIngredient(name: "Kycklingbröst", amountText: "500", unit: "g", groupIndex: 0),
                    DemoIngredient(name: "Vitlöksklyfta", amountText: "1", unit: "pcs", groupIndex: 0),
                    DemoIngredient(name: "Naturell Yoghurt", amountText: "1", unit: "dl", groupIndex: 0),
                    DemoIngredient(name: "Tikka masala-krydda", amountText: "1", unit: "tbsp", groupIndex: 0),
                    DemoIngredient(name: "Gul lök", amountText: "2", unit: "pcs", groupIndex: 1),
                    DemoIngredient(name: "Vitlöksklyftor", amountText: "2", unit: "pcs", groupIndex: 1),
                    DemoIngredient(name: "Färsk ingefära", amountText: "1", unit: "tsp", groupIndex: 1),
                    DemoIngredient(name: "Krossade tomater", amountText: "1", unit: "can", groupIndex: 1),
                    DemoIngredient(name: "Koriander", amountText: "1", unit: "bunch", groupIndex: 1),
                    DemoIngredient(name: "Basmatiris eller annat ris", amountText: "3", unit: "dl", groupIndex: 2)
                ]
            )

            return (primary, grouped)
        case .english:
            let primary = DemoRecipeData(
                title: "Pancakes (demo)",
                servings: 4,
                imageAssetName: "demo_pancakes",
                instructions: """
1. Mix flour, sugar and salt.
2. Whisk in half of the milk until smooth.
3. Add the rest of the milk and the eggs.
4. Melt the butter and stir in.
5. Fry thin pancakes in butter.
""",
                groupTitles: [
                    localized("ingredients", language: .english),
                    nil,
                    nil
                ],
                ingredients: [
                    DemoIngredient(name: "Flour", amountText: "2.5", unit: "dl"),
                    DemoIngredient(name: "Milk", amountText: "5", unit: "dl"),
                    DemoIngredient(name: "Eggs", amountText: "2", unit: "pcs"),
                    DemoIngredient(name: "Butter", amountText: "2", unit: "tbsp"),
                    DemoIngredient(name: "Salt", amountText: "1", unit: "pinch")
                ]
            )

            let grouped = DemoRecipeData(
                title: "Chicken tikka masala (demo)",
                servings: 4,
                imageAssetName: "tikka_masala",
                instructions: """
Marinated chicken

1. Mix the ingredients in a bowl.
Cut the chicken into pieces, add it to the marinade and leave for 15 minutes.

Tikka masala sauce

2. Saute onion, garlic and ginger for the sauce in a little oil.

3. Add chopped coriander and crushed tomatoes, then simmer for 15 minutes.

4. Cook the chicken with the marinade and stir it into the sauce.

To serve

5. Season with salt and black pepper, top with coriander.
Serve with rice.
""",
                groupTitles: [
                    "Marinated chicken",
                    "Tikka masala sauce",
                    "To serve"
                ],
                ingredients: [
                    DemoIngredient(name: "Chicken breast", amountText: "500", unit: "g", groupIndex: 0),
                    DemoIngredient(name: "Garlic clove", amountText: "1", unit: "", groupIndex: 0),
                    DemoIngredient(name: "Plain yoghurt", amountText: "1", unit: "dl", groupIndex: 0),
                    DemoIngredient(name: "Tikka spice powder", amountText: "1", unit: "tbsp", groupIndex: 0),
                    DemoIngredient(name: "Onion", amountText: "2", unit: "pcs", groupIndex: 1),
                    DemoIngredient(name: "Garlic cloves", amountText: "2", unit: "", groupIndex: 1),
                    DemoIngredient(name: "Fresh ginger", amountText: "1", unit: "tsp", groupIndex: 1),
                    DemoIngredient(name: "Crushed tomatoes", amountText: "1", unit: "can", groupIndex: 1),
                    DemoIngredient(name: "Fresh coriander", amountText: "1", unit: "bunch", groupIndex: 1),
                    DemoIngredient(name: "Basmati rice or other rice", amountText: "3", unit: "dl", groupIndex: 2)
                ]
            )

            return (primary, grouped)
        case .system:
            return (
                DemoRecipeData(
                    title: "",
                    servings: 0,
                    imageAssetName: "",
                    instructions: "",
                    groupTitles: [nil, nil, nil],
                    ingredients: []
                ),
                DemoRecipeData(
                    title: "",
                    servings: 0,
                    imageAssetName: "",
                    instructions: "",
                    groupTitles: [nil, nil, nil],
                    ingredients: []
                )
            )
        }
    }

    private static func resolvedLanguage(
        from selectedLanguage: AppLanguage
    ) -> AppLanguage {
        switch selectedLanguage {
        case .system:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            return code == "sv" ? .swedish : .english
        case .swedish, .english:
            return selectedLanguage
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
        locale: Locale,
        language: AppLanguage,
        data: DemoRecipeData
    ) -> UUID? {
        guard !data.title.isEmpty else { return nil }

        let recipe = Recipe(context: context)
        let recipeID = UUID()
        recipe.id = recipeID
        recipe.title = data.title
        recipe.sortTitle = data.title.sortKey(locale: locale)
        recipe.instructions = data.instructions
        recipe.date = Date()
        recipe.baseServings = Int16(data.servings)
        recipe.group1Title = normalizedGroupTitle(
            titleAt(index: 0, in: data.groupTitles)
        ) ?? localized("ingredients", language: language)
        recipe.group2Title = normalizedGroupTitle(
            titleAt(index: 1, in: data.groupTitles)
        )
        recipe.group3Title = normalizedGroupTitle(
            titleAt(index: 2, in: data.groupTitles)
        )

        recipe.imageFilename = saveDemoImageIfAvailable(named: data.imageAssetName)

        for item in data.ingredients {
            let ingredient = IngredientEntity(context: context)
            ingredient.id = UUID()
            ingredient.name = item.name
            ingredient.unit = item.unit
            ingredient.amountText = item.amountText
            ingredient.amount = IngredientFormatter.parseAmount(
                item.amountText,
                locale: locale
            ) ?? 0
            ingredient.scalable = true
            ingredient.pluralName = nil
            ingredient.groupIndex = Int16(item.groupIndex)
            ingredient.recipe = recipe
        }

        do {
            try context.save()
            AppLog.storage.debug("Demo-recept skapat: \(data.title, privacy: .public)")
            return recipeID
        } catch {
            AppLog.storage.error(
                "Kunde inte spara demo-recept: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }

    private static func persistDemoState(
        defaults: UserDefaults,
        language: AppLanguage,
        primaryDemoID: UUID?,
        groupedDemoID: UUID?
    ) {
        defaults.set(true, forKey: didSeedKey)

        if let primaryDemoID {
            defaults.set(primaryDemoID.uuidString, forKey: demoRecipeIDKey)
        } else {
            defaults.removeObject(forKey: demoRecipeIDKey)
        }

        if let groupedDemoID {
            defaults.set(groupedDemoID.uuidString, forKey: groupedDemoRecipeIDKey)
        } else {
            defaults.removeObject(forKey: groupedDemoRecipeIDKey)
        }

        defaults.set(language.rawValue, forKey: demoLanguageKey)
        defaults.set(currentDemoSeedVersion, forKey: demoSeedVersionKey)
    }

    private static func validDemoID(
        from rawValue: String?,
        key: String,
        defaults: UserDefaults
    ) -> UUID? {
        guard let rawValue else { return nil }
        guard let id = UUID(uuidString: rawValue) else {
            defaults.removeObject(forKey: key)
            return nil
        }
        return id
    }

    private static func removeTrackingIfRecipeMissing(
        id: UUID?,
        key: String,
        context: NSManagedObjectContext,
        defaults: UserDefaults
    ) -> UUID? {
        guard let id else { return nil }
        if fetchRecipe(id: id, context: context) == nil {
            defaults.removeObject(forKey: key)
            return nil
        }
        return id
    }

    private static func deleteDemoRecipeIfExists(
        id: UUID?,
        context: NSManagedObjectContext
    ) {
        guard let id else { return }
        guard let recipe = fetchRecipe(id: id, context: context) else { return }
        if let filename = recipe.imageFilename {
            FileHelper.deleteImage(filename: filename)
        }
        context.delete(recipe)
        try? context.save()
    }

    private static func localized(
        _ key: String,
        language: AppLanguage
    ) -> String {
        switch language {
        case .system:
            return NSLocalizedString(key, comment: "")
        case .swedish:
            return localized(key, languageCode: "sv")
        case .english:
            return localized(key, languageCode: "en")
        }
    }

    private static func localized(
        _ key: String,
        languageCode: String
    ) -> String {
        guard
            let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, comment: "")
        }

        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    private static func normalizedGroupTitle(_ value: String?) -> String? {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func titleAt(
        index: Int,
        in titles: [String?]
    ) -> String? {
        guard titles.indices.contains(index) else { return nil }
        return titles[index]
    }

    private static func attachImageIfNeeded(
        to recipe: Recipe,
        imageName: String,
        context: NSManagedObjectContext
    ) {
        guard recipe.imageFilename?.isEmpty ?? true else { return }
        guard let filename = saveDemoImageIfAvailable(named: imageName) else { return }
        recipe.imageFilename = filename
        try? context.save()
    }

    private static func saveDemoImageIfAvailable(named imageName: String) -> String? {
        guard !imageName.isEmpty else { return nil }
        guard let image = UIImage(named: imageName) else {
            AppLog.storage.debug("Demo-bild saknas i Assets: \(imageName, privacy: .public)")
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
    let imageAssetName: String
    let instructions: String
    let groupTitles: [String?]
    let ingredients: [DemoIngredient]
}

private struct DemoIngredient {
    let name: String
    let amountText: String
    let unit: String
    let groupIndex: Int

    init(
        name: String,
        amountText: String,
        unit: String,
        groupIndex: Int = 0
    ) {
        self.name = name
        self.amountText = amountText
        self.unit = unit
        self.groupIndex = groupIndex
    }
}
