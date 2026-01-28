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
        baseServings: Int
    ) -> String {
        let scale = Double(servings) / Double(max(1, baseServings))
        let amount = ingredient.amount * scale
        
        let amountString = amount.cleanString
        let unit = ingredient.unit ?? ""
        let name = ingredient.name ?? ""
        
        return "\(amountString) \(unit) \(name)"
    }
}
