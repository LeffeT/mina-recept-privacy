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

        // Grund
        "st": "pcs",
        "g": "g",
        "kg": "kg",
        "ml": "ml",
        "dl": "dl",
        "l": "l",

        // Skedar
        "tsk": "tsp",
        "msk": "tbsp",
        "kryddmått": "krm",
        "nypa": "pinch",

        // NYA – styckbaserade
        "skiva": "slice",
        "klyfta": "wedge",
        "halva": "half",
        "vitlöksklyfta": "clove",

        // Förpackningar
        "burk": "can",
        "glas": "jar",
        "förp": "pack",

        // Grönt
        "knippe": "bunch",
        "blad": "leaf",
        "stjälk": "stalk"
    ]

    return map[value, default: value]
}

