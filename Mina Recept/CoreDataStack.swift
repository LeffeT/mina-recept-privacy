//
//  CoreDataStack.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//


import CoreData

enum CoreDataStack {

    static let shared: NSPersistentContainer = {
        let modelURL = Bundle.main.url(
            forResource: "Matlagning",
            withExtension: "momd"
        )!

        let model = NSManagedObjectModel(contentsOf: modelURL)!

        let container = NSPersistentContainer(
            name: "Matlagning",
            managedObjectModel: model
        )

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()
}
