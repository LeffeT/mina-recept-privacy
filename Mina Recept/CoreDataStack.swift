//
//  CoreDataStack.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//


import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        let modelURL = Bundle.main.url(
            forResource: "Matlagning",
            withExtension: "momd"
        )!

        let model = NSManagedObjectModel(contentsOf: modelURL)!

        container = NSPersistentContainer(
            name: "Matlagning",
            managedObjectModel: model
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

