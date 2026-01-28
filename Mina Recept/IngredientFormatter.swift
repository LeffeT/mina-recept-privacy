//
//  IngredientFormatter.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-18.
//


struct IngredientFormatter {

    static func formattedLine(
        ingredient: IngredientEntity,
        servings: Int,
        baseServings: Int,
        languageManager: LanguageManager
     
    ) -> String {

        let scale = Double(servings) / Double(max(1, baseServings))
        let amount = ingredient.amount * scale
        let amountString = amount.cleanString

        let unitKey = ingredient.unit ?? ""
        let unit = unitKey.isEmpty
            ? ""
            : L("unit.\(unitKey)", languageManager)

        let name = ingredient.name ?? ""

        return "\(amountString) \(unit) \(name)"
    }
}

