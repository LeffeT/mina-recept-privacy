//
//  CoreDataStack.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//


import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {

        container = NSPersistentCloudKitContainer(name: "Matlagning")

        // CloudKit-koppling
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.cloudKitContainerOptions =
            NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.se.leiftarvainen.minarecept"
            )

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }

        container.viewContext.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

