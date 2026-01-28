//
//  PendingRecipePayloadStore.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//


//
//  PendingRecipePayloadStore.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//

import Foundation

enum PendingRecipePayloadStore {

    private static let key = "PendingRecipePayload"

    // Spara payload lokalt (vid delning)
    static func save(_ payload: PendingRecipePayload) {
        do {
            let data = try JSONEncoder().encode(payload)
            UserDefaults.standard.set(data, forKey: key)
            print("📦 Pending payload saved:", payload.id)
        } catch {
            print("❌ Failed to save pending payload:", error)
        }
    }

    // Ladda payload (vid import)
    static func load() -> PendingRecipePayload? {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let payload = try? JSONDecoder().decode(PendingRecipePayload.self, from: data)
        else {
            return nil
        }
        return payload
    }

    // Rensa efter lyckad import
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        print("🧹 Pending payload cleared")
    }
}
