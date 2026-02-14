//
//  AppTheme.swift
//  Matlagning
//
//  Created by Leif Tarvainen on 2025-12-17.
//


import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {

    case white
    case orange
    case green
    case black
    case blue
    case pink
    case red


    // MARK: - Identifiable
    var id: String { rawValue }

    // MARK: - Visningsnamn (för SetupView)
    var displayName: String {
        switch self {
        case .white: return "Vit"
        case .orange: return "Orange"
        case .green:  return "Grön"
        case .black:   return "Svart"
        case .blue:   return "Blå"
        case .pink:   return "Rosa"
        case .red:    return "Röd"
        }
    }

    // MARK: - Bakgrund (standard i hela appen)
    var backgroundGradient: LinearGradient {
        switch self {

        case .white:
            return LinearGradient(
                colors: [
                    Color(white: 0.98),
                    Color(white: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

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

        case .black:
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
        case .pink:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.55, blue: 0.70),
                    Color(red: 0.55, green: 0.15, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .red:
            return LinearGradient(
                colors: [
                    Color(red: 0.80, green: 0.15, blue: 0.15),
                    Color(red: 0.35, green: 0.05, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        }
    }

    // MARK: - Knappbakgrund (flat / glas-look)
    var buttonBackground: Color {
        switch self {
        case .white: return Color.black.opacity(0.08)
        case .orange: return Color.white.opacity(0.18)
        case .green:  return Color.white.opacity(0.22)
        case .black:   return Color.white.opacity(0.15)
        case .blue:   return Color.white.opacity(0.20)
        case .pink:   return Color.white.opacity(0.18)
        case .red:    return Color.white.opacity(0.16)
        }
    }
    // MARK: - Kortbakgrund (receptkort, ingredienser m.m.)
    var cardBackground: Color {
        switch self {
        case .white: return Color.black.opacity(0.05)
        case .orange: return Color.white.opacity(0.10)
        case .green:  return Color.white.opacity(0.12)
        case .black:   return Color.white.opacity(0.08)
        case .blue:   return Color.white.opacity(0.12)
        case .pink:   return Color.white.opacity(0.11)
        case .red:    return Color.white.opacity(0.09)
        }
    }

    // MARK: - Textfärg (för framtiden)
    var primaryTextColor: Color {
        switch self {
        case .white: return .black
        case .orange, .green, .black, .blue, .pink, .red:
            return .white
        }
    }
    // MARK: - Destructive (delete / danger)
    var destructiveColor: Color {
        switch self {
        case .white: return .red
        case .orange: return .red.opacity(0.9)
        case .green:  return .red.opacity(0.85)
        case .black:   return .red.opacity(0.75)
        case .blue:   return .red.opacity(0.85)
        case .pink:   return .white.opacity(0.85)
        case .red:   return .white.opacity(0.85)
        }
    }

    // MARK: - Accent (outline / glow)
    var accentColor: Color {
        switch self {
        case .white: return .black
        case .orange: return .orange
        case .green:  return .green
        case .black:   return .gray
        case .blue:   return .blue
        case .pink:   return .pink
        case .red:    return .red        }
    }
}
