//
//  SwedishSort.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-01.
//
import Foundation

extension String {

    /// Språkanpassad sortnyckel
    func sortKey(locale: Locale) -> String {

        // Nordiska språk – korrekt Å Ä Ö
        if let languageCode = locale.language.languageCode?.identifier,
           ["sv", "da", "no"].contains(languageCode) {

            return self
                .lowercased()
                .replacingOccurrences(of: "å", with: "{")
                .replacingOccurrences(of: "ä", with: "|")
                .replacingOccurrences(of: "ö", with: "}")
        }

        // Alla andra språk
        return self.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: locale
        )
    }
}
