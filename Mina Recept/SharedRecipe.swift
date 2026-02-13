//
//  SharedRecipe.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-11.
//


import Foundation

struct SharedRecipeDTO: Codable {
    let id: UUID
    let title: String
    let instructions: String
    let baseServings: Int
    let ingredients: [SharedIngredientDTO]
}

struct SharedIngredientDTO: Codable {
    let name: String
    let amount: Double
    let unit: String
}

