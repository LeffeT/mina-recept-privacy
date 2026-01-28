//
//  RecipeScaler.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-15.
//


import Foundation

struct RecipeScaler {

    static func scaledAmount(
        ingredient: IngredientEntity,
        recipe: Recipe,
        targetServings: Int
    ) -> Double {

        // Ingredienser som inte ska skalas (t.ex. salt)
        guard ingredient.scalable else {
            return ingredient.safeAmount
        }

        let base = max(1, Int(recipe.baseServings))

        let value =
            ingredient.safeAmount
            * Double(targetServings)
            / Double(base)

        return rounded(value)
    }

    private static func rounded(_ value: Double) -> Double {
        if value < 1 {
            return (value * 10).rounded() / 10
        } else {
            return (value * 2).rounded() / 2
        }
    }
}
