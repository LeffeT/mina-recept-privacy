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

    /// Delningslänkens utgångstid
    let expiresAt: Date?

    /// Antal portioner i originalreceptet
    let baseServings: Int
    
    /// Gruppnamn för ingredienser (max 3)
    let groupTitles: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case instructions
        case imageFilename
        case ingredients
        case expiresAt
        case baseServings
        case groupTitles
    }

    init(
        id: String,
        title: String,
        instructions: String,
        imageFilename: String?,
        ingredients: [PendingIngredient],
        expiresAt: Date?,
        baseServings: Int,
        groupTitles: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.imageFilename = imageFilename
        self.ingredients = ingredients
        self.expiresAt = expiresAt
        self.baseServings = baseServings
        self.groupTitles = groupTitles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        instructions = try container.decode(String.self, forKey: .instructions)
        imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
        ingredients = try container.decode([PendingIngredient].self, forKey: .ingredients)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        baseServings = try container.decodeIfPresent(Int.self, forKey: .baseServings) ?? 1
        groupTitles = try container.decodeIfPresent([String].self, forKey: .groupTitles)
    }
}

extension PendingRecipePayload {
    func withExpiresAt(_ date: Date?) -> PendingRecipePayload {
        PendingRecipePayload(
            id: id,
            title: title,
            instructions: instructions,
            imageFilename: imageFilename,
            ingredients: ingredients,
            expiresAt: date,
            baseServings: baseServings,
            groupTitles: groupTitles
        )
    }
}
