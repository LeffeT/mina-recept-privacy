//
//  CloudKitService.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-12.
//


import CloudKit
import UIKit

final class CloudKitService {
    
    static let shared = CloudKitService()
    
    private let container = CKContainer.default()
    
    private var privateDB: CKDatabase {
        container.privateCloudDatabase
    }
    
    // MARK: - Create Share
    
    func savePublicRecipe(_ payload: PendingRecipePayload) {
        
        let database = container.publicCloudDatabase
        
        let recordID = CKRecord.ID(recordName: payload.id)
        let record = CKRecord(recordType: "RecipeShare", recordID: recordID)
        
        record["title"] = payload.title as CKRecordValue
        record["instructions"] = payload.instructions as CKRecordValue

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
                print("Image file missing at:", fileURL.path)
                return
            }
            record["image"] = CKAsset(fileURL: fileURL)
        }


        
        database.save(record) { _, error in
            if let error {
                print("❌ CloudKit save error:", error)
            } else {
                print("✅ Saved to public CloudKit")
            }
        }
    }

    // MARK: - Fetch Share

    func fetchPublicRecipe(id: String, completion: @escaping (PendingRecipePayload?) -> Void) {
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: id)

        database.fetch(withRecordID: recordID) { record, error in
            if let error {
                print("❌ CloudKit fetch error:", error)
                completion(nil)
                return
            }

            guard let record else {
                completion(nil)
                return
            }

            if let data = record["payload"] as? Data,
               let payload = try? JSONDecoder().decode(PendingRecipePayload.self, from: data) {
                let finalPayload = self.attachImageIfNeeded(
                    payload: payload,
                    record: record,
                    fallbackID: id
                )
                completion(finalPayload)
                return
            }

            let title = record["title"] as? String ?? ""
            let instructions = record["instructions"] as? String ?? ""
            let ingredientsText = record["ingredients"] as? String ?? ""
            let ingredients = self.parseIngredients(from: ingredientsText)

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
                ingredients: ingredients
            )

            completion(payload)
        }
    }

    // MARK: - Helpers

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
                ingredients: payload.ingredients
            )
        }

        return payload
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
