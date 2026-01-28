//
//  Localization.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-03.
//
import Foundation

func L(_ key: String, _ languageManager: LanguageManager) -> String {
    let languageCode: String

    switch languageManager.selectedLanguage {
    case .system:
        return NSLocalizedString(key, comment: "")
    case .swedish:
        languageCode = "sv"
    case .english:
        languageCode = "en"
    }

    guard
        let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
        let bundle = Bundle(path: path)
    else {
        return NSLocalizedString(key, comment: "")
    }

    return NSLocalizedString(key, bundle: bundle, comment: "")
}

