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
        
        let ingredientText = payload.ingredients.map {
            "\($0.name) \($0.amount) \($0.unit)"
        }.joined(separator: "\n")
        
        record["ingredients"] = ingredientText as CKRecordValue
        
        if let filename = payload.imageFilename {

            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let fileURL = documents.appendingPathComponent(filename)

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
}


