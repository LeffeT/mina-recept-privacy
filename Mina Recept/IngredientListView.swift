//
//  IngredientListView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-18.
//
import SwiftUI

struct IngredientListView: View {
    let ingredients: [TempIngredient]
    let themeManager: ThemeManager
    let languageManager: LanguageManager
   // let scale: Double          // ✅ NY
    let onDelete: ((TempIngredient) -> Void)?   // valfri delete

    var body: some View {
        if !ingredients.isEmpty {
            VStack(spacing: 8) {
                ForEach(ingredients) { ing in

                    ZStack(alignment: .trailing) {
                        
                        HStack {
                            Text(
                                IngredientFormatter.formattedLine(
                                    ingredient: ing,
                                    languageManager: languageManager
                                )
                            )
                            
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            
                            Spacer()
                        }
                        
                        if let onDelete {
                            Button {
                                onDelete(ing)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(themeManager.currentTheme.destructiveColor)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 12)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.cardBackground)
                    )
                }
            }
        }
    }
}
