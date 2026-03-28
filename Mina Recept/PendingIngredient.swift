//
//  PendingIngredient.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-18.
//
import SwiftUI
import Foundation

nonisolated struct PendingIngredient: Codable {
    let name: String
    let amount: Double
    let amountText: String?
    let unit: String
    let groupIndex: Int

    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case amountText
        case unit
        case groupIndex
    }

    init(name: String, amount: Double, amountText: String?, unit: String, groupIndex: Int = 0) {
        self.name = name
        self.amount = amount
        self.amountText = amountText
        self.unit = unit
        self.groupIndex = groupIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        amountText = try container.decodeIfPresent(String.self, forKey: .amountText)
        unit = try container.decode(String.self, forKey: .unit)
        groupIndex = try container.decodeIfPresent(Int.self, forKey: .groupIndex) ?? 0
    }
}
