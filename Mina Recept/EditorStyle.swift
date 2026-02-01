//
//  EditorStyle.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-17.
//


import SwiftUI

struct EditorStyle: ViewModifier {
    let theme: ThemeManager

    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(theme.currentTheme.primaryTextColor)
            .padding(12)
            .frame(minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.currentTheme.buttonBackground)
            )
            .scrollContentBackground(.hidden)
    }
}
