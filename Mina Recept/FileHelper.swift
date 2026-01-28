//
//  FileHelper.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-27.
//


//
//  FileHelper.swift
//  Mina Recept
//

import UIKit

enum FileHelper {

    // MARK: - App Group ID (MÅSTE matcha Share Extension)
    private static let appGroupID = "group.se.leiftarvainen.minarecept"

    // MARK: - Base directory (App Group container)
    private static var baseDirectory: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("❌ Kunde inte hitta App Group container")
        }
        return url
    }

    static func fileURL(for filename: String) -> URL {
        baseDirectory.appendingPathComponent(filename)
    }

    // MARK: - Save image
    static func saveImageData(filename: String, data: Data) {
        let url = fileURL(for: filename)
        do {
            try data.write(to: url, options: [.atomic])
            print("✅ Bild sparad i App Group:", url.lastPathComponent)
        } catch {
            print("❌ Kunde inte spara bild:", error)
        }
    }

    // MARK: - Load image
    static func loadImage(filename: String) -> UIImage? {
        let url = fileURL(for: filename)
        guard
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)
        else {
            print("⚠️ Kunde inte läsa bild:", filename)
            return nil
        }
        return image
    }

    // MARK: - Image URL (för delning / preview)
    static func imageURL(filename: String) -> URL? {
        let url = fileURL(for: filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Delete image
    static func deleteImage(filename: String) {
        let url = fileURL(for: filename)
        do {
            try FileManager.default.removeItem(at: url)
            print("🗑️ Bild borttagen:", url.lastPathComponent)
        } catch {
            print("⚠️ Kunde inte ta bort bild:", error)
        }
    }
}
