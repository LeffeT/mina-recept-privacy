//
//  IngredientFormatter.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-18.
//


import Foundation

struct IngredientFormatter {

    static func parseAmount(_ text: String, locale: Locale) -> Double? {
        var normalized = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else { return nil }

        // Normalize spacing around slash and mixed numbers (e.g. "1-1/2")
        if normalized.contains("/") {
            normalized = normalized
                .replacingOccurrences(of: " / ", with: "/")
                .replacingOccurrences(of: " /", with: "/")
                .replacingOccurrences(of: "/ ", with: "/")
                .replacingOccurrences(of: "-", with: " ")
        }

        // Mixed number: "1 1/2"
        let parts = normalized.split(whereSeparator: { $0 == " " })
        if parts.count == 2, let fraction = parseFraction(String(parts[1])) {
            let whole = Double(parts[0]) ?? 0
            return whole + fraction
        }

        // Fraction only: "1/2"
        if parts.count == 1, let fraction = parseFraction(String(parts[0])) {
            return fraction
        }

        return Double(normalized)
    }

    private static func parseFraction(_ text: String) -> Double? {
        let parts = text.split(separator: "/")
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0
        else {
            return nil
        }
        return numerator / denominator
    }


    // MARK: - Core Data ingredient (RecipeDetailView)
    static func formattedLine(
        ingredient: IngredientEntity,
        servings: Int,
        baseServings: Int,
        languageManager: LanguageManager
    ) -> String {

        let scale = Double(servings) / Double(max(1, baseServings))
        let amount = ingredient.amount * scale
        let rawAmountText = ingredient.amountText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let amountString = (servings == baseServings && !rawAmountText.isEmpty)
            ? rawAmountText
            : amount.cleanString

        let unitKey = ingredient.unit ?? ""
        let unit = unitKey.isEmpty
            ? ""
            : L("unit.\(unitKey)", languageManager)

        let name = ingredient.name ?? ""

        if unit.isEmpty {
            return "\(amountString) \(name)"
        }
        return "\(amountString) \(unit) \(name)"
    }

    // MARK: - Temp ingredient (Add / Edit)
    static func formattedLine(
        ingredient: TempIngredient,
        languageManager: LanguageManager
    ) -> String {

        let amountString = {
            let raw = ingredient.amountText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return raw.isEmpty ? ingredient.amount.cleanString : raw
        }()

        let unitKey = ingredient.unit
        let unit = unitKey.isEmpty
            ? ""
            : L("unit.\(unitKey)", languageManager)

        if unit.isEmpty {
            return "\(amountString) \(ingredient.name)"
        }
        return "\(amountString) \(unit) \(ingredient.name)"
    }
}
