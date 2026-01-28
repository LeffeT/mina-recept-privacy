//
//  Untitled.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-16.
//

import SwiftUI
import Foundation

func pluralize(_ name: String, amount: Double) -> String {
    amount == 1 ? name : name + "ar"
}


struct IngredientRowView: View {
    let ingredient: IngredientEntity
    let servings: Int
    let baseServings: Int
    let themeManager: ThemeManager

    var body: some View {
        Text(
            IngredientFormatter.formattedLine(
                ingredient: ingredient,
                servings: servings,
                baseServings: baseServings
            )
        )
        .foregroundStyle(.white)
    }
}

