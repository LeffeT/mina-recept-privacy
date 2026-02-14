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
import os


enum FileHelper {

    private static let imageCache = NSCache<NSString, UIImage>()

    private static var iCloudDirectory: URL? {
        FileManager.default
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
    }

    static func imageURL(filename: String) -> URL? {
        guard let dir = iCloudDirectory else { return nil }
        return dir.appendingPathComponent(filename)
    }


    // MARK: - Save image

    static func saveImageData(filename: String, data: Data) {

        guard let dir = iCloudDirectory else {
            AppLog.storage.error("iCloud container saknas")
            return
        }

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let url = dir.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            if let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: filename as NSString)
            }

            AppLog.storage.debug("Sparad i iCloud: \(url.path, privacy: .private)")

        } catch {
            AppLog.storage.error("Kunde inte spara i iCloud: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Load image

    static func loadImage(filename: String) -> UIImage? {
        if let cached = imageCache.object(forKey: filename as NSString) {
            return cached
        }

        guard let dir = iCloudDirectory else {
            AppLog.storage.error("iCloud container saknas vid läsning")
            return nil
        }

        let url = dir.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: url.path),
           let image = UIImage(contentsOfFile: url.path) {
            imageCache.setObject(image, forKey: filename as NSString)
            return image
        }

        AppLog.storage.debug("Kunde inte läsa bild: \(filename, privacy: .public)")
        return nil
    }

    static func loadImageAsync(
        filename: String,
        completion: @escaping (UIImage?) -> Void
    ) {
        if let cached = imageCache.object(forKey: filename as NSString) {
            completion(cached)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let image = loadImage(filename: filename)
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    // MARK: - Delete

    static func deleteImage(filename: String) {

        guard let dir = iCloudDirectory else { return }

        let url = dir.appendingPathComponent(filename)

        try? FileManager.default.removeItem(at: url)
        imageCache.removeObject(forKey: filename as NSString)
    }
}
