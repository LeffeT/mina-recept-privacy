//
//  ThemeManager.swift
//  Matlagning
//
//  Created by Leif Tarvainen on 2025-12-17.
//
import SwiftUI
import Combine


@MainActor
final class ThemeManager: ObservableObject {

    @Published var currentTheme: AppTheme = .orange {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "theme")
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "theme"),
           let theme = AppTheme(rawValue: saved) {
            currentTheme = theme
        }
    }
}
