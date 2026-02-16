//
//  IngredientEditorView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-15.
//


import SwiftUI
import CoreData

struct IngredientEditorView: View {

    @ObservedObject var recipe: Recipe
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var name = ""
    @State private var amount = ""
    @State private var unit = ""

    var body: some View {
        VStack(spacing: 16) {

            // MARK: - Lista ingredienser
            List {
                ForEach(recipe.ingredientArray, id: \.id) { ingredient in
                    HStack {
                        Text(ingredient.safeName)
                        Spacer()
                        Text("\(ingredient.safeAmount, specifier: "%.1f") \(ingredient.safeUnit)")
                    }
                }
                .onDelete(perform: deleteIngredient)
            }

            Divider()

            // MARK: - Lägg till ny ingrediens
            VStack(spacing: 12) {

                TextField(
                    "",
                    text: $name,
                    prompt: Text("Ingrediens")
                        .foregroundColor(themeManager.currentTheme.placeholderTextColor)
                )
                    .textFieldStyle(.roundedBorder)

                TextField(
                    "",
                    text: $amount,
                    prompt: Text("Mängd (per 1 portion)")
                        .foregroundColor(themeManager.currentTheme.placeholderTextColor)
                )
                   // .keyboardType(.decimalPad)
                    .keyboardType(.numbersAndPunctuation)


                    .textFieldStyle(.roundedBorder)

                TextField(
                    "",
                    text: $unit,
                    prompt: Text("Enhet (t.ex. dl, g, kg)")
                        .foregroundColor(themeManager.currentTheme.placeholderTextColor)
                )
                    .textFieldStyle(.roundedBorder)

                Button("Lägg till ingrediens") {
                    addIngredient()
                }
                .disabled(name.isEmpty || amount.isEmpty || unit.isEmpty)
            }
        }
        .padding()
        .navigationTitle("Ingredienser")
    }


    // MARK: - Actions

    private func addIngredient() {
        guard
            !name.isEmpty,
            !unit.isEmpty,
            let value = IngredientFormatter.parseAmount(
                        amount,
                        locale: languageManager.locale
                        )
            
            
        else {
            return
        }



        let ingredient = IngredientEntity(context: context)
        ingredient.name = name
        ingredient.amount = value
        ingredient.unit = unit
        ingredient.scalable = true
        ingredient.recipe = recipe

        try? context.save()

        name = ""
        amount = ""
        unit = ""
    }


    private func deleteIngredient(at offsets: IndexSet) {
        for index in offsets {
            let ingredient = recipe.ingredientArray[index]
            context.delete(ingredient)
        }
        try? context.save()
    }
}
