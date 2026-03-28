//
//  CloudSyncStatus.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-13.
//



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
    @Published private(set) var isCheckingAvailability = false
    @Published private(set) var isRecipeStartupLoading = false

    private let container: NSPersistentCloudKitContainer
    private var cancellables = Set<AnyCancellable>()
    private var activeEventIDs = Set<UUID>()
    private var syncStartDate: Date?
    private var syncingEndHoldTask: Task<Void, Never>?
    private let minimumSyncDuration: TimeInterval = 10.0
    private var availabilityRefreshID = UUID()

    private var hasCompletedRecipeStartupLoad = false
    private var recipeStartupLoadingTimedOut = false
    private var recipeStartupHasRecipes = false
    private var hasRequestedRecipeStartupDemoSeed = false
    private var recipeStartupLoadingTimeoutTask: Task<Void, Never>?
    private let recipeStartupBeganAt = Date()
    private var lastRecipeStartupSyncActivityAt = Date()
    private let recipeStartupDemoSeedMinimumDelay: TimeInterval = 6.0
    private let recipeStartupDemoSeedMaximumDelay: TimeInterval = 18.0
    private let recipeStartupDemoSeedSettleWindow: TimeInterval = 2.5

    init(container: NSPersistentCloudKitContainer) {
        self.container = container
        updateAvailability()
        observeEvents()
        observeLocalChanges()
        refreshAccountStatus()
    }

    convenience init() {
        self.init(container: CoreDataStack.shared.container)
    }

    func refresh() {
        noteRecipeStartupSyncActivity()
        updateAvailability()
        refreshAccountStatus()
    }

    var isBackgroundSyncActive: Bool {
        isCheckingAvailability || state == .syncing
    }

    var shouldSeedRecipesOnStartup: Bool {
        !hasRequestedRecipeStartupDemoSeed && !recipeStartupHasRecipes
    }

    var canAttemptRecipeStartupDemoSeed: Bool {
        guard shouldSeedRecipesOnStartup else { return false }

        let elapsed = Date().timeIntervalSince(recipeStartupBeganAt)
        if !FileHelper.isICloudAvailable() || state == .unavailable {
            return elapsed >= 1.6
        }

        guard elapsed >= recipeStartupDemoSeedMinimumDelay else {
            return false
        }

        let hasSettled =
            Date().timeIntervalSince(lastRecipeStartupSyncActivityAt) >=
            recipeStartupDemoSeedSettleWindow

        if !isCheckingAvailability && state != .syncing && hasSettled {
            return true
        }

        return elapsed >= recipeStartupDemoSeedMaximumDelay
    }

    func setRecipeStartupHasRecipes(_ hasRecipes: Bool) {
        recipeStartupHasRecipes = hasRecipes
        if hasRecipes {
            hasRequestedRecipeStartupDemoSeed = true
            finishRecipeStartupLoading(markCompleted: true)
            return
        }

        guard !hasCompletedRecipeStartupLoad else {
            isRecipeStartupLoading = false
            cancelRecipeStartupLoadingTasks()
            return
        }

        isRecipeStartupLoading = true
        scheduleRecipeStartupLoadingTimeoutIfNeeded()
    }

    func markRecipeStartupDemoSeedRequested() {
        hasRequestedRecipeStartupDemoSeed = true
    }

    private func noteRecipeStartupSyncActivity() {
        guard !hasCompletedRecipeStartupLoad else { return }
        lastRecipeStartupSyncActivityAt = Date()
    }

    private func updateAvailability() {
        let available = FileHelper.isICloudAvailable()
        if !available {
            markUnavailable()
        } else if state == .unavailable {
            state = .idle
        }
    }

    private func refreshAccountStatus() {
        guard FileHelper.isICloudAvailable() else {
            markUnavailable()
            return
        }

        let refreshID = UUID()
        availabilityRefreshID = refreshID
        noteRecipeStartupSyncActivity()
        isCheckingAvailability = true

        CKContainer.default().accountStatus { status, error in
            Task { @MainActor in
                guard refreshID == self.availabilityRefreshID else { return }
                guard FileHelper.isICloudAvailable() else {
                    self.markUnavailable()
                    return
                }

                if let error {
                    self.lastError = error.localizedDescription
                }

                switch status {
                case .available:
                    self.verifyContainerAccess(refreshID: refreshID)
                case .noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable:
                    self.markUnavailable()
                @unknown default:
                    self.markUnavailable()
                }
            }
        }
    }

    private func verifyContainerAccess(refreshID: UUID) {
        CKContainer.default().privateCloudDatabase.fetchAllRecordZones { _, error in
            Task { @MainActor in
                guard refreshID == self.availabilityRefreshID else { return }
                guard FileHelper.isICloudAvailable() else {
                    self.markUnavailable()
                    return
                }

                self.isCheckingAvailability = false
                self.noteRecipeStartupSyncActivity()

                if let ckError = error as? CKError {
                    if self.isAccessDeniedError(ckError) {
                        self.markUnavailable()
                        return
                    }

                    if self.isTransientSyncError(ckError) {
                        self.lastError = ckError.localizedDescription
                        if self.state == .unavailable || self.state == .error {
                            self.state = .idle
                        }
                        return
                    }

                    self.state = .error
                    self.lastError = ckError.localizedDescription
                    return
                }

                if let error {
                    self.state = .error
                    self.lastError = error.localizedDescription
                    return
                }

                if self.state == .unavailable || self.state == .error {
                    self.state = .idle
                }
                self.lastError = nil
            }
        }
    }

    private func isAccessDeniedError(_ error: CKError) -> Bool {
        switch error.code {
        case .notAuthenticated,
             .permissionFailure,
             .badContainer,
             .missingEntitlement:
            return true
        default:
            return false
        }
    }

    private func markUnavailable() {
        state = .unavailable
        lastError = nil
        isCheckingAvailability = false
    }

    private func scheduleRecipeStartupLoadingTimeoutIfNeeded() {
        guard recipeStartupLoadingTimeoutTask == nil else { return }

        recipeStartupLoadingTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 25_000_000_000)
            guard let self, !Task.isCancelled else { return }

            self.recipeStartupLoadingTimedOut = true
            self.finishRecipeStartupLoading(markCompleted: true)
        }
    }

    private func finishRecipeStartupLoading(markCompleted: Bool) {
        if markCompleted {
            hasCompletedRecipeStartupLoad = true
        }
        isRecipeStartupLoading = false
        cancelRecipeStartupLoadingTasks()
    }

    private func cancelRecipeStartupLoadingTasks() {
        recipeStartupLoadingTimeoutTask?.cancel()
        recipeStartupLoadingTimeoutTask = nil
    }

    private func observeEvents() {
        NotificationCenter.default
            .publisher(
                for: NSPersistentCloudKitContainer.eventChangedNotification,
                object: container
            )
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
                    self.noteRecipeStartupSyncActivity()
                    self.activeEventIDs.insert(event.identifier)
                    if self.state != .unavailable && self.state != .syncing {
                        self.syncStartDate = Date()
                        self.state = .syncing
                    }
                    return
                }

                self.activeEventIDs.remove(event.identifier)
                self.noteRecipeStartupSyncActivity()

                if let error = event.error {
                    if self.isTransientSyncError(error) {
                        self.lastError = error.localizedDescription
                        if self.activeEventIDs.isEmpty {
                            self.state = .idle
                            self.syncStartDate = nil
                        }
                        return
                    }

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

    private func isTransientSyncError(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }

        switch ckError.code {
        case .changeTokenExpired,
             .zoneBusy,
             .serviceUnavailable,
             .requestRateLimited,
             .networkFailure,
             .networkUnavailable,
             .partialFailure:
            return true
        default:
            return false
        }
    }

    private func observeLocalChanges() {
        NotificationCenter.default
            .publisher(
                for: .NSManagedObjectContextDidSave,
                object: container.viewContext
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self else { return }
                guard self.state != .unavailable else { return }

                let inserts = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>
                let updates = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>
                let deletes = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>

                let hasChanges =
                    (inserts?.isEmpty == false) ||
                    (updates?.isEmpty == false) ||
                    (deletes?.isEmpty == false)

                guard hasChanges else { return }
                self.markLocalChange()
            }
            .store(in: &cancellables)
    }

    private func markLocalChange() {
        syncingEndHoldTask?.cancel()

        guard state != .unavailable else { return }
        noteRecipeStartupSyncActivity()

        if state != .syncing {
            syncStartDate = Date()
            state = .syncing
        }
    }
}
