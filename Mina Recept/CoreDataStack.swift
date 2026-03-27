//
//  CoreDataStack.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//

import CoreData
import Combine

final class CoreDataStack: ObservableObject {

    static let shared = CoreDataStack()

    let container: NSPersistentCloudKitContainer
    @Published private(set) var isLoaded = false

    private let loadQueue = DispatchQueue(
        label: "se.leiftarvainen.minarecept.coredata.load",
        qos: .userInitiated
    )
    private var hasStartedLoading = false

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
    }

    func loadIfNeeded() {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true

        loadQueue.async { [weak self] in
            guard let self else { return }

            self.container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Core Data error: \(error)")
                }

                DispatchQueue.main.async {
                    self.container.viewContext.mergePolicy =
                        NSMergeByPropertyObjectTrumpMergePolicy
                    self.container.viewContext.automaticallyMergesChangesFromParent = true
                    self.isLoaded = true
                }
            }
        }
    }
}
