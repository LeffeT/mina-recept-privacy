//
//  PendingIngredient.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-18.
//
import SwiftUI
import Foundation

struct PendingIngredient: Codable {
    let name: String
    let amount: Double
    let unit: String
}
