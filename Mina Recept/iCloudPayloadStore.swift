//
//  iCloudPayloadStore.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-09.
//


import Foundation
import os.log

enum iCloudPayloadStore {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MatlagningApp",
        category: "iCloudPayloadStore"
    )

    // MARK: - Save

    static func save(_ payload: PendingRecipePayload) {
        guard
            let data = try? JSONEncoder().encode(payload),
            let url = fileURL(for: payload.id)
        else {
            logger.error("❌ iCloud save: kunde inte skapa data eller url")
            return
        }

        // 🔒 Idempotent save – spara bara om filen inte finns
        if FileManager.default.fileExists(atPath: url.path) {
            logger.info("⏭ Payload already exists, skipping save: \(payload.id)")
            return
        }

        do {
            try data.write(to: url)
            logger.info("📦 iCloud payload saved: \(payload.id)")
        } catch {
            logger.error("❌ iCloud save failed for \(payload.id): \(error.localizedDescription)")
            
        }
    }

    // MARK: - Load

    static func load(id: String) -> PendingRecipePayload? {
        guard let url = fileURL(for: id) else {
            logger.error("❌ iCloud load: ingen url för \(id)")
            return nil
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            // Missing payload is normal when CloudKit is the primary source.
            return nil
        }

        logger.info("☁️ iCloud load → \(url.path)")

        guard let data = try? Data(contentsOf: url) else {
            logger.error("❌ iCloud load: ingen data på url")
            return nil
        }

        do {
            return try JSONDecoder().decode(PendingRecipePayload.self, from: data)
        } catch {
            logger.error("❌ iCloud decode failed for \(id): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Clear

    static func clear(id: String) {
        guard let url = fileURL(for: id) else { return }

        do {
            try FileManager.default.removeItem(at: url)
            logger.info("🗑 iCloud payload cleared: \(id)")
        } catch {
            //logger.error("❌ iCloud clear failed for \(id): \(error.localizedDescription)")
            if (error as NSError).code == NSFileNoSuchFileError {
                logger.info("ℹ️ iCloud payload already cleared: \(id)")
            } else {
                logger.error("❌ iCloud clear failed for \(id): \(error.localizedDescription)")
            }

        }
    }

    // MARK: - Helpers

    private static func fileURL(for id: String) -> URL? {
        FileManager.default
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("\(id).json")
    }
}
