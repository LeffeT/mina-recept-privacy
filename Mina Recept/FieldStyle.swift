//
//  FieldStyle.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-17.
//


import SwiftUI

struct FieldStyle: ViewModifier {
    let theme: ThemeManager

    func body(content: Content) -> some View {
        content
            //.foregroundStyle(.white)
            .padding(12)
            .tint(.white) // 👈 MARKÖREN
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.currentTheme.buttonBackground)
            )
            .foregroundStyle(theme.currentTheme.primaryTextColor)
    }
}
