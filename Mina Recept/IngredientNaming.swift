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
