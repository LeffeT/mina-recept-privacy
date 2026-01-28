//
//  AppLanguage.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-01.
//


import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case swedish
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .swedish: return "Svenska"
        case .english: return "English"
        }
    }
}
