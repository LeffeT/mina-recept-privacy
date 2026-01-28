//
//  Untitled.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-16.
//

import Foundation

// Formatterar 1 → "1", 1.5 → "1.5"
extension Double {
    var cleanString: String {
        truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(self))
        : String(format: "%.1f", self)
    }
}

// Enkel singular/plural-logik
func ingredientName(base: String, amount: Double) -> String {
    if abs(amount - 1.0) < 0.0001 {
        return base
    } else {
        return base + "ar"   // fisk → fiskar, tomat → tomatar (kan förbättras senare)
    }
}
func scaledAmount(
    ingredient: IngredientEntity,
    recipe: Recipe,
    servings: Int
) -> Double {
    let base = Double(recipe.baseServings)
    guard base > 0 else { return ingredient.amount }
    return ingredient.amount * Double(servings) / base
}

func ingredientDisplayText(
    ingredient: IngredientEntity,
    recipe: Recipe,
    servings: Int
) -> String {

    let scaledAmount = RecipeScaler.scaledAmount(
        ingredient: ingredient,
        recipe: recipe,
        targetServings: servings
    )

    let name = ingredientName(
        base: ingredient.safeName,
        amount: scaledAmount
    )

    return "\(scaledAmount.cleanString) \(name)"
}

