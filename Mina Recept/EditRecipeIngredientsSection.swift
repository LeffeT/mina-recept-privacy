//
//  EditRecipeIngredientsSection.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-19.
//



//
//  EditRecipeView+Ingredients.swift
//  Mina Recept
//
//  🔒 ADDITIV FIL
//  Lägger till servings + ingredienshantering till EditRecipeView
//  RÖR INTE befintlig layout, body eller UI-struktur
//

import SwiftUI
import CoreData
import os

// MARK: - Ingredients Section (kan användas inne i befintlig EditRecipeView)

struct EditRecipeIngredientsSection: View {

    @ObservedObject var recipe: Recipe

    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager

    @State private var servings: Int
    @State private var showIngredientEditor = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: Int(recipe.baseServings))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Servings (samma logik som DetailRecipeView)
            HStack {
                Text("servings: \(servings)")
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

                Spacer()

                Button {
                    if servings > 1 { servings -= 1 }
                } label: {
                    Image(systemName: "minus")
                }

                Button {
                    servings += 1
                } label: {
                    Image(systemName: "plus")
                }
            }

            // MARK: - Ingredienslista
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recipe.ingredientArray, id: \.id) { ingredient in
                    IngredientRowView(
                        ingredient: ingredient,
                        servings: servings,
                        baseServings: Int(recipe.baseServings),
                        themeManager: themeManager,
                        languageManager: languageManager
                    )
                    .swipeActions {
                        Button(role: .destructive) {
                            delete(ingredient)
                        } label: {
                            Label("Ta bort", systemImage: "trash")
                        }
                    }
                }
            }

            // MARK: - Lägg till ingrediens
            Button {
                showIngredientEditor = true
            } label: {
                Label("Lägg till ingrediens", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showIngredientEditor) {
            IngredientEditorView(recipe: recipe)
                .environmentObject(themeManager)
        }
        .onChange(of: servings) { _, newValue in
            recipe.baseServings = Int16(newValue)
        }
    }

    // MARK: - Logic

    private func delete(_ ingredient: IngredientEntity) {
        context.delete(ingredient)
        do {
            try context.save()
        } catch {
           #if DEBUG
            AppLog.storage.error("Could not delete ingredient: \(error.localizedDescription, privacy: .public)")
           #endif
        }
    }
}
