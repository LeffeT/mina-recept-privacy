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

        if FileManager.default.fileExists(atPath: url.path) {
            if let image = UIImage(contentsOfFile: url.path) {
                imageCache.setObject(image, forKey: filename as NSString)
                return image
            }

            // File exists but is not readable yet → trigger download
            if isUbiquitousFile(url) {
                startDownloadingIfNeeded(url)
                return nil
            }
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

        loadImageAsync(
            filename: filename,
            retries: 3,
            delay: 0.8,
            completion: completion
        )
    }

    private static func loadImageAsync(
        filename: String,
        retries: Int,
        delay: TimeInterval,
        completion: @escaping (UIImage?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = loadImage(filename: filename)
            if let image {
                DispatchQueue.main.async {
                    completion(image)
                }
                return
            }

            guard retries > 0,
                  let url = imageURL(filename: filename),
                  isUbiquitousFile(url)
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(
                deadline: .now() + delay
            ) {
                loadImageAsync(
                    filename: filename,
                    retries: retries - 1,
                    delay: delay * 1.6,
                    completion: completion
                )
            }
        }
    }

    private static func isUbiquitousFile(_ url: URL) -> Bool {
        FileManager.default.isUbiquitousItem(at: url)
    }

    private static func startDownloadingIfNeeded(_ url: URL) {
        guard FileManager.default.isUbiquitousItem(at: url) else { return }
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
            AppLog.storage.debug("iCloud download start: \(url.lastPathComponent, privacy: .public)")
        } catch {
            AppLog.storage.error("iCloud download failed: \(error.localizedDescription, privacy: .public)")
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
