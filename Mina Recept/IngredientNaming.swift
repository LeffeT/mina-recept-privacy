//
//  Untitled.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-16.
//
import Foundation

func displayName(
    singular: String,
    plural: String,
    amount: Double
) -> String {
    if abs(amount - 1.0) < 0.0001 {
        return singular
    } else {
        return plural
    }
}

func unitKey(fromLocalized value: String) -> String {
    let map: [String: String] = [
        "st": "pcs",
        "g": "g",
        "kg": "kg",
        "ml": "ml",
        "dl": "dl",
        "l": "l",
        "tsk": "tsp",
        "msk": "tbsp",
        "kryddmått": "krm",
        "nypa": "pinch"
    ]

    return map[value, default: value]
}
