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
            print("❌ iCloud container saknas")
            return
        }

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let url = dir.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)

            print("☁️ Sparad i iCloud:", url)

        } catch {
            print("❌ Kunde inte spara i iCloud:", error)
        }
    }

    // MARK: - Load image

    static func loadImage(filename: String) -> UIImage? {

        guard let dir = iCloudDirectory else {
            print("❌ iCloud container saknas vid läsning")
            return nil
        }

        let url = dir.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: url.path) {
            return UIImage(contentsOfFile: url.path)
        }

        print("❌ Kunde inte läsa bild:", filename)
        return nil
    }

    // MARK: - Delete

    static func deleteImage(filename: String) {

        guard let dir = iCloudDirectory else { return }

        let url = dir.appendingPathComponent(filename)

        try? FileManager.default.removeItem(at: url)
    }
}
