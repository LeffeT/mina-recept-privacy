//
//  CloudSyncStatus.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-13.
//

import Combine
import CloudKit
import CoreData
import Foundation

@MainActor
final class CloudSyncStatus: ObservableObject {
    enum State {
        case unavailable
        case idle
        case syncing
        case error
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastError: String?
    @Published private(set) var lastSyncDate: Date?

    private let container: NSPersistentCloudKitContainer
    private var cancellables = Set<AnyCancellable>()
    private var activeEventIDs = Set<UUID>()
    private var syncStartDate: Date?
    private var syncingEndHoldTask: Task<Void, Never>?
    private let minimumSyncDuration: TimeInterval = 10.0

    init(container: NSPersistentCloudKitContainer) {
        self.container = container
        updateAvailability()
        observeEvents()
        refreshAccountStatus()
    }

    convenience init() {
        self.init(container: CoreDataStack.shared.container)
    }

    func refresh() {
        updateAvailability()
        refreshAccountStatus()
    }

    private func updateAvailability() {
        let available = FileManager.default.ubiquityIdentityToken != nil
        if !available {
            state = .unavailable
        } else if state == .unavailable {
            state = .idle
        }
    }

    private func refreshAccountStatus() {
        CKContainer.default().accountStatus { status, error in
            Task { @MainActor in
                if let error {
                    self.lastError = error.localizedDescription
                }
                switch status {
                case .available:
                    if self.state == .unavailable {
                        self.state = .idle
                    }
                case .noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable:
                    self.state = .unavailable
                @unknown default:
                    self.state = .unavailable
                }
            }
        }
    }

    private func observeEvents() {
        NotificationCenter.default
            .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification,
                       object: container)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self else { return }
                guard let event = notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event else {
                    return
                }

                self.syncingEndHoldTask?.cancel()

                if event.endDate == nil {
                    self.activeEventIDs.insert(event.identifier)
                    if self.state != .unavailable && self.state != .syncing {
                        self.syncStartDate = Date()
                        self.state = .syncing
                    }
                    return
                }

                self.activeEventIDs.remove(event.identifier)

                if let error = event.error {
                    self.state = .error
                    self.lastError = error.localizedDescription
                    return
                }

                self.lastSyncDate = event.endDate

                guard self.state != .unavailable else { return }
                guard self.activeEventIDs.isEmpty else { return }

                let startDate = self.syncStartDate ?? Date()
                let elapsed = Date().timeIntervalSince(startDate)
                let remaining = max(0, self.minimumSyncDuration - elapsed)

                if remaining > 0 {
                    self.syncingEndHoldTask = Task { @MainActor in
                        try? await Task.sleep(
                            nanoseconds: UInt64(remaining * 1_000_000_000)
                        )
                        guard self.activeEventIDs.isEmpty,
                              self.state != .unavailable,
                              self.state != .error
                        else { return }
                        self.state = .idle
                        self.syncStartDate = nil
                    }
                } else {
                    self.state = .idle
                    self.syncStartDate = nil
                }
            }
            .store(in: &cancellables)
    }
}
