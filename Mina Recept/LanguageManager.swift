//
//  LanguageManager.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-01.
//


//
//  LanguageManager.swift
//  Mina Recept
//

import Foundation
import Combine

final class LanguageManager: ObservableObject {

    static let shared = LanguageManager()

    private let key = "selectedLanguage"

    @Published var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: key)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: key)
        self.selectedLanguage = AppLanguage(rawValue: saved ?? "") ?? .system
    }

    var locale: Locale {
        switch selectedLanguage {
        case .system:
            return .current
        case .swedish:
            return Locale(identifier: "sv")
        case .english:
            return Locale(identifier: "en")
        }
    }
}
