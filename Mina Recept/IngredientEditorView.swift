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

                TextField("Ingrediens", text: $name)
                    .textFieldStyle(.roundedBorder)

                TextField("Mängd (per 1 portion)", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Enhet (t.ex. dl, g, kg)", text: $unit)
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
        // ⛔ Stoppa skapande om receptet inte är sparat ännu
            guard !recipe.objectID.isTemporaryID else {
                return
            }

            guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
                return
            }
        let ingredient = IngredientEntity(context: context)
       
        ingredient.name = name
        ingredient.amount = value
        ingredient.unit = unit
        ingredient.scalable = true          // 🔑 KRITISKT
        ingredient.recipe = recipe          // 🔑 KRITISKT

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
