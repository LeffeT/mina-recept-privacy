//
//  SetupView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-03.
//


import SwiftUI

struct SetupView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 28) {

                Text(L("settings_title", languageManager))
                    .font(.largeTitle.bold())
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

                // MARK: - Tema
                VStack(spacing: 12) {

                    Button(L("theme_orange", languageManager)) {
                        themeManager.currentTheme = .orange
                    }

                    Button(L("theme_green", languageManager)) {
                        themeManager.currentTheme = .green
                    }

                    Button(L("theme_black", languageManager)) {
                        themeManager.currentTheme = .black
                    }

                    Button(L("theme_blue", languageManager)) {
                        themeManager.currentTheme = .blue
                    }
                    Button(L("theme_pink", languageManager)) {
                        themeManager.currentTheme = .pink
                    }

                    Button(L("theme_red", languageManager)) {
                        themeManager.currentTheme = .red
                    }

                }
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)

                Divider()
                    .background(
                        themeManager.currentTheme.primaryTextColor.opacity(0.3)
                    )

                // MARK: - Språk
                VStack(alignment: .leading, spacing: 12) {

                    Text(L("language", languageManager))
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)

                    Picker(
                        L("language", languageManager),
                        selection: $languageManager.selectedLanguage
                    ) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()

                Button(L("close", languageManager)) {
                    dismiss()
                }
                .padding(.top, 20)
            }
            .padding(32)
        }
    }
}
