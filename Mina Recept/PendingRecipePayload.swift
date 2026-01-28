//
//  PendingRecipePayload.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//


//
//  PendingRecipePayload.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//

import Foundation

/// Temporär payload som används vid delning via Mail / SMS
/// Sparas lokalt tills användaren importerar receptet
struct PendingRecipePayload: Codable {

    /// ID som används i minarecept://import?id=...
    let id: String

    /// Recepttitel
    let title: String

    /// Instruktioner / text
    let instructions: String

    /// Valfritt bildfilnamn (lagras via FileHelper)
    let imageFilename: String?
    
    let ingredients: [PendingIngredient]
}
