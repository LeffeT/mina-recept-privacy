//
//  IngredientEntity+Helpers.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-15.
//
import Foundation

extension IngredientEntity {
    var safeAmount: Double { amount }
    var safeUnit: String { unit ?? "" }
    var safeName: String { name ?? "" }
}

