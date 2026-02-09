//
//  SharedRecipePayload.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-06.
//


struct SharedRecipePayload: Codable {
    let title: String
    let instructions: String
    let ingredients: [SharedIngredient]
}

struct SharedIngredient: Codable {
    let name: String
    let amount: Double
    let unit: String
}
