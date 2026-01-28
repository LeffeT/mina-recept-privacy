//
//  RecipeEntity+Helpers..swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-15.
//

import Foundation

extension Recipe {
    var ingredientArray: [IngredientEntity] {
        let set = ingredients as? Set<IngredientEntity> ?? []
        return set.sorted { $0.safeName < $1.safeName }
    }
}
