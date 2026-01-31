//
//  ThemedTextField.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-29.
//


import SwiftUI

struct ThemedTextField: View {
    let key: String
    @Binding var text: String
    let keyboard: UIKeyboardType

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        TextField(L(key, languageManager), text: $text)
            .keyboardType(keyboard)
            .tint(themeManager.currentTheme.primaryTextColor)
            .padding(12)
            .background(themeManager.currentTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }
}
