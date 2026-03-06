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

    enum ImageStorage {
        case iCloudOnly
        case iCloudWithFallback
        case localOnly
    }

    struct ImageStorageReport {
        let localCount: Int
        let localBytes: Int64
        let iCloudCount: Int
        let iCloudBytes: Int64

        static let empty = ImageStorageReport(
            localCount: 0,
            localBytes: 0,
            iCloudCount: 0,
            iCloudBytes: 0
        )

        var totalCount: Int { localCount + iCloudCount }
        var totalBytes: Int64 { localBytes + iCloudBytes }
    }

    struct ImageCleanupResult {
        let localRemoved: Int
        let localBytesRemoved: Int64
        let iCloudRemoved: Int
        let iCloudBytesRemoved: Int64

        var totalRemoved: Int { localRemoved + iCloudRemoved }
        var totalBytesRemoved: Int64 { localBytesRemoved + iCloudBytesRemoved }
    }

    private static let imageCache = NSCache<NSString, UIImage>()
    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png"]

    private static var iCloudDirectory: URL? {
        FileManager.default
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
    }

    private static var localDirectory: URL? {
        guard let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first else { return nil }
        return base.appendingPathComponent("LocalImages", isDirectory: true)
    }

    static func imageURL(filename: String) -> URL? {
        guard let dir = iCloudDirectory else { return nil }
        return dir.appendingPathComponent(filename)
    }

    static func localImageURL(filename: String) -> URL? {
        guard let dir = localDirectory else { return nil }
        return dir.appendingPathComponent(filename)
    }

    private static func ensureDirectory(_ dir: URL) throws {
        try FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
    }


    // MARK: - Save image

    @discardableResult
    static func saveImageData(
        filename: String,
        data: Data,
        storage: ImageStorage = .iCloudWithFallback
    ) -> Bool {
        AppLog.storage.debug(
            "Save image: \(filename, privacy: .public) storage=\(String(describing: storage), privacy: .public)"
        )
        switch storage {
        case .localOnly:
            return saveToLocal(filename: filename, data: data)
        case .iCloudOnly:
            return saveToICloud(filename: filename, data: data)
        case .iCloudWithFallback:
            if saveToICloud(filename: filename, data: data) {
                removeLocalIfExists(filename: filename)
                return true
            }
            return saveToLocal(filename: filename, data: data)
        }
    }

    // MARK: - Load image

    static func loadImage(filename: String) -> UIImage? {
        if let cached = imageCache.object(forKey: filename as NSString) {
            return cached
        }

        if let dir = iCloudDirectory {
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
        }

        if let localDir = localDirectory {
            let localURL = localDir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: localURL.path),
               let image = UIImage(contentsOfFile: localURL.path) {
                imageCache.setObject(image, forKey: filename as NSString)
                return image
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
        if let dir = iCloudDirectory {
            let url = dir.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }

        if let dir = localDirectory {
            let url = dir.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
        imageCache.removeObject(forKey: filename as NSString)
    }

    // MARK: - Pending local images

    static func flushPendingImagesIfPossible() {
        guard FileManager.default.ubiquityIdentityToken != nil else { return }
        guard let localDir = localDirectory else { return }
        guard let cloudDir = iCloudDirectory else { return }

        guard FileManager.default.fileExists(atPath: localDir.path) else {
            return
        }

        AppLog.storage.debug(
            "Flush pending images: local=\(localDir.path, privacy: .private) cloud=\(cloudDir.path, privacy: .private)"
        )

        do {
            try ensureDirectory(cloudDir)
        } catch {
            AppLog.storage.error("Kunde inte skapa iCloud-mapp: \(error.localizedDescription, privacy: .public)")
            return
        }

        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(
                at: localDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            AppLog.storage.error("Kunde inte läsa lokal bildmapp: \(error.localizedDescription, privacy: .public)")
            return
        }

        guard !files.isEmpty else { return }

        for file in files {
            let target = cloudDir.appendingPathComponent(file.lastPathComponent)

            if FileManager.default.fileExists(atPath: target.path) {
                try? FileManager.default.removeItem(at: file)
                continue
            }

            do {
                try FileManager.default.moveItem(at: file, to: target)
                AppLog.storage.debug("Flyttad till iCloud: \(target.lastPathComponent, privacy: .public)")
            } catch {
                AppLog.storage.error("Kunde inte flytta till iCloud: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private static func saveToICloud(filename: String, data: Data) -> Bool {
        guard let dir = iCloudDirectory else {
            AppLog.storage.error("iCloud container saknas")
            return false
        }

        do {
            try ensureDirectory(dir)
            let url = dir.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            if let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: filename as NSString)
            }
            AppLog.storage.debug("Sparad i iCloud: \(url.path, privacy: .private)")
            return true
        } catch {
            AppLog.storage.error("Kunde inte spara i iCloud: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private static func saveToLocal(filename: String, data: Data) -> Bool {
        guard let dir = localDirectory else {
            AppLog.storage.error("Local image dir saknas")
            return false
        }

        do {
            try ensureDirectory(dir)
            let url = dir.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            if let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: filename as NSString)
            }
            AppLog.storage.debug("Sparad lokalt: \(url.path, privacy: .private)")
            return true
        } catch {
            AppLog.storage.error("Kunde inte spara lokalt: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private static func removeLocalIfExists(filename: String) {
        guard let dir = localDirectory else { return }
        let url = dir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Storage report & cleanup

    static func imageStorageReport() -> ImageStorageReport {
        let localFiles = localDirectory.flatMap { imageFiles(in: $0) } ?? []
        let iCloudFiles = iCloudDirectory.flatMap { imageFiles(in: $0) } ?? []

        let localBytes = localFiles.reduce(Int64(0)) { $0 + fileSize($1) }
        let iCloudBytes = iCloudFiles.reduce(Int64(0)) { $0 + fileSize($1) }

        return ImageStorageReport(
            localCount: localFiles.count,
            localBytes: localBytes,
            iCloudCount: iCloudFiles.count,
            iCloudBytes: iCloudBytes
        )
    }

    static func cleanupOrphanedImages(
        referencedFilenames: Set<String>
    ) -> ImageCleanupResult {
        var localRemoved = 0
        var localBytesRemoved: Int64 = 0
        var iCloudRemoved = 0
        var iCloudBytesRemoved: Int64 = 0

        if let localDir = localDirectory {
            for file in imageFiles(in: localDir) {
                guard !referencedFilenames.contains(file.lastPathComponent) else {
                    continue
                }
                let bytes = fileSize(file)
                if (try? FileManager.default.removeItem(at: file)) != nil {
                    localRemoved += 1
                    localBytesRemoved += bytes
                }
            }
        }

        if let cloudDir = iCloudDirectory {
            for file in imageFiles(in: cloudDir) {
                guard !referencedFilenames.contains(file.lastPathComponent) else {
                    continue
                }
                let bytes = fileSize(file)
                if (try? FileManager.default.removeItem(at: file)) != nil {
                    iCloudRemoved += 1
                    iCloudBytesRemoved += bytes
                }
            }
        }

        return ImageCleanupResult(
            localRemoved: localRemoved,
            localBytesRemoved: localBytesRemoved,
            iCloudRemoved: iCloudRemoved,
            iCloudBytesRemoved: iCloudBytesRemoved
        )
    }

    private static func imageFiles(in directory: URL) -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            return []
        }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return files.filter { url in
            let ext = url.pathExtension.lowercased()
            guard imageExtensions.contains(ext) else { return false }
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return !isDir
        }
    }

    private static func fileSize(_ url: URL) -> Int64 {
        let value = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        return Int64(value ?? 0)
    }
}
