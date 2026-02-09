//
//  PendingRecipePayloadStore.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-04.
//


import Foundation

enum PendingRecipePayloadStore {

    private static let prefix = "PendingRecipePayload_"

    private static func key(for id: String) -> String {
        "\(prefix)\(id)"
    }

    // MARK: - Save

    static func save(_ payload: PendingRecipePayload) {
        do {
            let data = try JSONEncoder().encode(payload)
            UserDefaults.standard.set(data, forKey: key(for: payload.id))
        #if DEBUG
            print("📦 Pending payload saved:", payload.id)
        #endif
        } catch {
        #if DEBUG
            print("❌ Failed to save payload:", error)
        #endif
        }
    }

    // MARK: - Load

    static func load(id: String) -> PendingRecipePayload? {
        guard
            let data = UserDefaults.standard.data(forKey: key(for: id)),
            let payload = try? JSONDecoder().decode(PendingRecipePayload.self, from: data)
        else {
            return nil
        }
        return payload
    }

    // MARK: - Exists

    static func exists(id: String) -> Bool {
        UserDefaults.standard.data(forKey: key(for: id)) != nil
    }

    // MARK: - Clear

    static func clear(id: String) {
        UserDefaults.standard.removeObject(forKey: key(for: id))
    #if DEBUG
        print("🧹 Pending payload cleared:", id)
    #endif
    }
}
