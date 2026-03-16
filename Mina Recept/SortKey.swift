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

        // Alltid sortera Å/Ä/Ö sist (svensk ordning), även i engelska läget.
        var key = self
            .lowercased()
            .replacingOccurrences(of: "å", with: "{")
            .replacingOccurrences(of: "ä", with: "|")
            .replacingOccurrences(of: "ö", with: "}")

        // För övriga tecken: normalisera accenter för stabil sortering.
        if let languageCode = locale.language.languageCode?.identifier,
           !["sv", "da", "no"].contains(languageCode) {
            key = key.folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: locale
            )
        }

        return key
    }
}
