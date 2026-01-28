//
//  AppTheme.swift
//  Matlagning
//
//  Created by Leif Tarvainen on 2025-12-17.
//


import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {

    case orange
    case green
    case dark
    case blue

    // MARK: - Identifiable
    var id: String { rawValue }

    // MARK: - Visningsnamn (för SetupView)
    var displayName: String {
        switch self {
        case .orange: return "Orange"
        case .green:  return "Grön"
        case .dark:   return "Mörk"
        case .blue:   return "Blå"
        }
    }

    // MARK: - Bakgrund (standard i hela appen)
    var backgroundGradient: LinearGradient {
        switch self {

        case .orange:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.58, blue: 0.18),
                    Color(red: 0.55, green: 0.25, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .green:
            return LinearGradient(
                colors: [
                    Color.green.opacity(0.55),
                    Color.green.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .dark:
            return LinearGradient(
                colors: [
                    Color.black,
                    Color.gray.opacity(0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .blue:
            return LinearGradient(
                colors: [
                    Color.blue.opacity(0.65),
                    Color.indigo
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Knappbakgrund (flat / glas-look)
    var buttonBackground: Color {
        switch self {
        case .orange: return Color.white.opacity(0.18)
        case .green:  return Color.white.opacity(0.22)
        case .dark:   return Color.white.opacity(0.15)
        case .blue:   return Color.white.opacity(0.20)
        }
    }
    // MARK: - Kortbakgrund (receptkort, ingredienser m.m.)
    var cardBackground: Color {
        switch self {
        case .orange: return Color.white.opacity(0.10)
        case .green:  return Color.white.opacity(0.12)
        case .dark:   return Color.white.opacity(0.08)
        case .blue:   return Color.white.opacity(0.12)
        }
    }

    // MARK: - Textfärg (för framtiden)
    var primaryTextColor: Color {
        .white
    }
    // MARK: - Destructive (delete / danger)
    var destructiveColor: Color {
        switch self {
        case .orange: return .red.opacity(0.9)
        case .green:  return .red.opacity(0.85)
        case .dark:   return .red.opacity(0.75)
        case .blue:   return .red.opacity(0.85)
        }
    }

    // MARK: - Accent (outline / glow)
    var accentColor: Color {
        switch self {
        case .orange: return .orange
        case .green:  return .green
        case .dark:   return .gray
        case .blue:   return .blue
        }
    }
}
