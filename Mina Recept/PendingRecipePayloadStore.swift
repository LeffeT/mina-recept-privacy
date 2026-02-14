//
//  PendingRecipePayloadStore.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-04.
//


import Foundation
import os

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
            AppLog.storage.debug("Pending payload saved: \(payload.id, privacy: .public)")
        #endif
        } catch {
        #if DEBUG
            AppLog.storage.error("Failed to save payload: \(error.localizedDescription, privacy: .public)")
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
        AppLog.storage.debug("Pending payload cleared: \(id, privacy: .public)")
    #endif
    }
}
