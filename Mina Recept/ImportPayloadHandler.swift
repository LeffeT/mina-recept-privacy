//
//  ImportPayloadHandler.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-01.
//


//
//  ImportPayloadHandler.swift
//  Mina Recept
//

import Foundation
import CoreData
import os



enum ImportPayloadHandler {

    // 📊 Central logger för import
    private static let logger = Logger(
        subsystem: "com.se.leiftarvainen.minarecept",
        category: "import"
    )

    static func importPendingRecipe(
        recipeID: String,
        onSuccess: @escaping () -> Void,
        onAlreadyImported: @escaping () -> Void
    ) {
        logger.info("Import start – recipeID: \(recipeID)")

        // 1️⃣ Hämta payload
        guard let payload = PendingRecipePayloadStore.load() else {
            logger.warning("Import skipped – already imported – recipeID: \(recipeID)")
            DispatchQueue.main.async {
                onAlreadyImported()
            }
            return
        }

        // 2️⃣ Core Data context
        let context = CoreDataStack.shared.viewContext

        // 3️⃣ Skapa Recipe
        let recipe = Recipe(context: context)

        recipe.id = UUID(uuidString: payload.id) ?? UUID()

        let finalTitle = payload.title.isEmpty ? "Nytt recept" : payload.title
        recipe.title = finalTitle

        // ✅ KORREKT svensk sortering
        //recipe.sortTitle = swedishSortKey(from: finalTitle)
        let locale = LanguageManager.shared.locale
        recipe.sortTitle = finalTitle.sortKey(locale: locale)


        recipe.instructions = payload.instructions
        recipe.date = Date()
        recipe.imageFilename = payload.imageFilename
        recipe.title = finalTitle
        
        // ✅ LÄGG TILL INGREDIENSER HÄR
            for item in payload.ingredients {
                let ingredient = IngredientEntity(context: context)
                ingredient.id = UUID()
                ingredient.name = item.name
                ingredient.amount = item.amount
                ingredient.unit = item.unit
                ingredient.recipe = recipe
            }


        // 4️⃣ Spara
        do {
            try context.save()

            PendingRecipePayloadStore.clear()
            logger.info("Import success – recipeID: \(recipeID)")

            DispatchQueue.main.async {
                onSuccess()
            }

        } catch {
            logger.error(
                "Import failed – recipeID: \(recipeID) – error: \(error.localizedDescription)"
            )
        }
    }
}
