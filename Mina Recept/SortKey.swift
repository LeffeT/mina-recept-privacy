//
//  SwedishSort.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-01.
//
import Foundation

extension String {

    /// Stabil sortnyckel som inte beror på valt appspråk.
    /// Å/Ä/Ö ligger alltid sist i svensk ordning, även i engelska läget.
    func sortKey(locale _: Locale) -> String {
        var key = self.lowercased()
            .replacingOccurrences(of: "å", with: "{")
            .replacingOccurrences(of: "ä", with: "|")
            .replacingOccurrences(of: "ö", with: "}")

        key = key.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )

        return key
    }
}
