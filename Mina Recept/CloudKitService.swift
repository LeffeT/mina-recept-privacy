//
//  CloudKitService.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-12.
//


import CloudKit
import UIKit
import os

final class CloudKitService {
    
    static let shared = CloudKitService()
    static let shareTTL: TimeInterval = 24 * 60 * 60
    
    private let container = CKContainer.default()
    private var cachedUserRecordName: String?
    
    private var privateDB: CKDatabase {
        container.privateCloudDatabase
    }
    
    // MARK: - Create Share
    
    func savePublicRecipe(_ payload: PendingRecipePayload) {
        let expiresAt = payload.expiresAt ?? Date().addingTimeInterval(Self.shareTTL)
        let payloadWithExpiry = payload.withExpiresAt(expiresAt)

        fetchUserRecordName { creatorRecordName in
            self.savePublicRecipeRecord(
                payload: payloadWithExpiry,
                expiresAt: expiresAt,
                creatorRecordName: creatorRecordName
            )
        }
    }

    // MARK: - Fetch Share
    enum FetchPublicRecipeResult {
        case success(PendingRecipePayload)
        case expired
        case notFound
        case failure(Error)
    }

    func fetchPublicRecipe(id: String, completion: @escaping (FetchPublicRecipeResult) -> Void) {
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: id)

        database.fetch(withRecordID: recordID) { record, error in
            if let error {
                if let ckError = error as? CKError, ckError.code == .unknownItem {
                    completion(.notFound)
                } else {
                    AppLog.cloudkit.error("Fetch error: \(error.localizedDescription, privacy: .public)")
                    completion(.failure(error))
                }
                return
            }

            guard let record else {
                completion(.notFound)
                return
            }

            Task { @MainActor in
                if let expiresAt = record["expiresAt"] as? Date, expiresAt <= Date() {
                    completion(.expired)
                    return
                }

                if let data = record["payload"] as? Data,
                   let payload = try? JSONDecoder().decode(PendingRecipePayload.self, from: data) {
                    let payloadWithExpiry = self.ensureExpiresAt(payload, record: record)
                    if let expiresAt = payloadWithExpiry.expiresAt, expiresAt <= Date() {
                        completion(.expired)
                        return
                    }

                    let finalPayload = self.attachImageIfNeeded(
                        payload: payloadWithExpiry,
                        record: record,
                        fallbackID: id
                    )
                    completion(.success(finalPayload))
                    return
                }

                let title = record["title"] as? String ?? ""
                let instructions = record["instructions"] as? String ?? ""
                let ingredientsText = record["ingredients"] as? String ?? ""
                let ingredients = self.parseIngredients(from: ingredientsText)
                let expiresAt = record["expiresAt"] as? Date

                var imageFilename: String? = nil
                if let asset = record["image"] as? CKAsset,
                   let fileURL = asset.fileURL,
                   let data = try? Data(contentsOf: fileURL) {
                    let filename = "\(id).jpg"
                    FileHelper.saveImageData(filename: filename, data: data)
                    imageFilename = filename
                }

                let payload = PendingRecipePayload(
                    id: id,
                    title: title,
                    instructions: instructions,
                    imageFilename: imageFilename,
                    ingredients: ingredients,
                    expiresAt: expiresAt
                )

                if let expiresAt, expiresAt <= Date() {
                    completion(.expired)
                    return
                }

                completion(.success(payload))
            }
        }
    }

    // MARK: - Delete Share

    func deletePublicRecipe(id: String) {
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: id)

        database.delete(withRecordID: recordID) { _, error in
            if let error {
                AppLog.cloudkit.error("Delete error: \(error.localizedDescription, privacy: .public)")
            } else {
                AppLog.cloudkit.info("Deleted CloudKit record: \(id, privacy: .public)")
            }
        }
    }

    // MARK: - Cleanup

    func cleanupExpiredSharesForCurrentUser() {
        fetchUserRecordName { creatorRecordName in
            guard let creatorRecordName else { return }

            let database = self.container.publicCloudDatabase
            let predicate = NSPredicate(
                format: "creatorID == %@ AND expiresAt < %@",
                creatorRecordName,
                Date() as NSDate
            )
            let query = CKQuery(recordType: "RecipeShare", predicate: predicate)
            let operation = CKQueryOperation(query: query)

            var recordIDs: [CKRecord.ID] = []
            operation.recordMatchedBlock = { recordID, result in
                if case .success = result {
                    recordIDs.append(recordID)
                }
            }

            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    guard !recordIDs.isEmpty else { return }
                    let deleteOperation = CKModifyRecordsOperation(
                        recordsToSave: nil,
                        recordIDsToDelete: recordIDs
                    )
                    deleteOperation.savePolicy = .ifServerRecordUnchanged
                    deleteOperation.modifyRecordsResultBlock = { result in
                        if case .failure(let error) = result {
                            AppLog.cloudkit.error("Cleanup delete error: \(error.localizedDescription, privacy: .public)")
                        }
                    }
                    database.add(deleteOperation)
                case .failure(let error):
                    AppLog.cloudkit.error("Cleanup query error: \(error.localizedDescription, privacy: .public)")
                }
            }

            database.add(operation)
        }
    }

    // MARK: - Helpers

    private func fetchUserRecordName(completion: @escaping (String?) -> Void) {
        if let cachedUserRecordName {
            completion(cachedUserRecordName)
            return
        }

        container.fetchUserRecordID { recordID, error in
            if let error {
                AppLog.cloudkit.error("User record fetch error: \(error.localizedDescription, privacy: .public)")
            }
            if let recordID {
                let recordName = recordID.recordName
                self.cachedUserRecordName = recordName
                completion(recordName)
            } else {
                completion(nil)
            }
        }
    }

    private func savePublicRecipeRecord(
        payload: PendingRecipePayload,
        expiresAt: Date,
        creatorRecordName: String?
    ) {
        let database = container.publicCloudDatabase

        let recordID = CKRecord.ID(recordName: payload.id)
        let record = CKRecord(recordType: "RecipeShare", recordID: recordID)

        record["title"] = payload.title as CKRecordValue
        record["instructions"] = payload.instructions as CKRecordValue
        record["expiresAt"] = expiresAt as CKRecordValue
        if let creatorRecordName {
            record["creatorID"] = creatorRecordName as CKRecordValue
        }

        if let data = try? JSONEncoder().encode(payload) {
            record["payload"] = data as NSData
        }

        let ingredientText = payload.ingredients.map {
            "\($0.name) \($0.amount) \($0.unit)"
        }.joined(separator: "\n")

        record["ingredients"] = ingredientText as CKRecordValue

        if let filename = payload.imageFilename,
           let fileURL = FileHelper.imageURL(filename: filename) {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                AppLog.cloudkit.error("Image file missing at: \(fileURL.path, privacy: .public)")
                return
            }
            record["image"] = CKAsset(fileURL: fileURL)
        }

        database.save(record) { _, error in
            if let error {
                AppLog.cloudkit.error("Save error: \(error.localizedDescription, privacy: .public)")
            } else {
                AppLog.cloudkit.info("Saved to public CloudKit")
            }
        }
    }

    private func attachImageIfNeeded(
        payload: PendingRecipePayload,
        record: CKRecord,
        fallbackID: String
    ) -> PendingRecipePayload {
        guard let asset = record["image"] as? CKAsset,
              let fileURL = asset.fileURL,
              let data = try? Data(contentsOf: fileURL)
        else {
            return payload
        }

        let filename = payload.imageFilename ?? "\(fallbackID).jpg"
        FileHelper.saveImageData(filename: filename, data: data)

        if payload.imageFilename == nil {
            return PendingRecipePayload(
                id: payload.id,
                title: payload.title,
                instructions: payload.instructions,
                imageFilename: filename,
                ingredients: payload.ingredients,
                expiresAt: payload.expiresAt
            )
        }

        return payload
    }

    private func ensureExpiresAt(
        _ payload: PendingRecipePayload,
        record: CKRecord
    ) -> PendingRecipePayload {
        guard payload.expiresAt == nil,
              let expiresAt = record["expiresAt"] as? Date
        else {
            return payload
        }

        return payload.withExpiresAt(expiresAt)
    }

    private func parseIngredients(from text: String) -> [PendingIngredient] {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0) }

        return lines.compactMap { line in
            let parts = line.split(separator: " ").map { String($0) }
            guard parts.count >= 3 else { return nil }

            let unit = parts[parts.count - 1]
            let amountString = parts[parts.count - 2]
                .replacingOccurrences(of: ",", with: ".")
            let nameParts = parts.dropLast(2)
            let name = nameParts.joined(separator: " ")
            let amount = Double(amountString) ?? 0

            return PendingIngredient(name: name, amount: amount, unit: unit)
        }
    }
}
