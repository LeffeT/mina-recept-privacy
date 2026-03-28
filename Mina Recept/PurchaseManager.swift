//
//  PurchaseManager.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-27.
//

import Foundation
import Combine
import StoreKit
import os

@MainActor
final class PurchaseManager: ObservableObject {
    enum RuntimeEnvironment {
        case debug
        case testFlight
        case appStore

        var storageValue: String {
            switch self {
            case .debug:
                return "debug"
            case .testFlight:
                return "testFlight"
            case .appStore:
                return "appStore"
            }
        }
    }

    nonisolated static let unlimitedProductID = "se.leiftarvainen.minarecept.unlimited"
    nonisolated static let freeRecipeLimit = 3

    private let entitlementKey = "iap_unlimited_unlocked"
    private let entitlementEnvironmentKey = "iap_unlimited_entitlement_environment"
    private let testUnlockKey = "iap_unlimited_test_unlock"
    private let legacyTestOverrideKey = "iap_unlimited_override"

    @Published private(set) var hasUnlimited: Bool = false
    @Published private(set) var hasStoreKitEntitlement: Bool = false
    @Published private(set) var isUsingTestUnlock: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private var updatesTask: Task<Void, Never>?

    nonisolated static var currentEnvironment: RuntimeEnvironment {
        #if DEBUG
        return .debug
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
            ? .testFlight
            : .appStore
        #endif
    }

    var runtimeEnvironment: RuntimeEnvironment {
        Self.currentEnvironment
    }

    var canUseTestUnlock: Bool {
        runtimeEnvironment != .appStore
    }

    init() {
        updatesTask = listenForTransactions()

        // Rensa gammalt testläge så att endast riktiga köp styr upplåsningen.
        if UserDefaults.standard.object(forKey: legacyTestOverrideKey) != nil {
            UserDefaults.standard.removeObject(forKey: legacyTestOverrideKey)
            UserDefaults.standard.removeObject(forKey: entitlementKey)
            UserDefaults.standard.removeObject(forKey: entitlementEnvironmentKey)
        }

        if !canUseTestUnlock {
            UserDefaults.standard.removeObject(forKey: testUnlockKey)
        }

        let savedEntitlementEnvironment = UserDefaults.standard.string(
            forKey: entitlementEnvironmentKey
        )
        hasStoreKitEntitlement =
            savedEntitlementEnvironment == runtimeEnvironment.storageValue &&
            UserDefaults.standard.bool(forKey: entitlementKey)
        isUsingTestUnlock = canUseTestUnlock &&
            UserDefaults.standard.bool(forKey: testUnlockKey)
        hasUnlimited = hasStoreKitEntitlement || isUsingTestUnlock

        Task { await refreshStatus() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(
                for: [Self.unlimitedProductID]
            )
        } catch {
            AppLog.app.error(
                "IAP: kunde inte hämta produkter: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func purchase() async -> Bool {
        guard let product = products.first else { return false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshStatus()
                    return true
                case .unverified:
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            AppLog.app.error(
                "IAP: köp misslyckades: \(error.localizedDescription, privacy: .public)"
            )
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshStatus()
        } catch {
            AppLog.app.error(
                "IAP: restore misslyckades: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func refreshStatus() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.unlimitedProductID {
                unlocked = true
                break
            }
        }

        let testUnlockEnabled = canUseTestUnlock &&
            UserDefaults.standard.bool(forKey: testUnlockKey)

        hasStoreKitEntitlement = unlocked
        isUsingTestUnlock = testUnlockEnabled
        hasUnlimited = unlocked || testUnlockEnabled
        UserDefaults.standard.set(unlocked, forKey: entitlementKey)
        UserDefaults.standard.set(
            runtimeEnvironment.storageValue,
            forKey: entitlementEnvironmentKey
        )
    }

    func setTestUnlockEnabled(_ enabled: Bool) {
        guard canUseTestUnlock else {
            UserDefaults.standard.removeObject(forKey: testUnlockKey)
            isUsingTestUnlock = false
            hasUnlimited = hasStoreKitEntitlement
            return
        }

        UserDefaults.standard.set(enabled, forKey: testUnlockKey)
        isUsingTestUnlock = enabled
        hasUnlimited = hasStoreKitEntitlement || enabled
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if case .verified(let transaction) = result,
                   transaction.productID == Self.unlimitedProductID {
                    await transaction.finish()
                    await self.refreshStatus()
                }
            }
        }
    }

}
