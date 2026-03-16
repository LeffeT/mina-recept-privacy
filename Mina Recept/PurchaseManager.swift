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
    nonisolated static let unlimitedProductID = "se.leiftarvainen.minarecept.unlimited"
    nonisolated static let freeRecipeLimit = 3

    private let entitlementKey = "iap_unlimited_unlocked"
    private let testOverrideKey = "iap_unlimited_override"

    @Published private(set) var hasUnlimited: Bool = UserDefaults.standard.bool(
        forKey: "iap_unlimited_unlocked"
    )
    @Published private(set) var testOverrideEnabled: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private var updatesTask: Task<Void, Never>?
    private var storeUnlocked = false

    init() {
        updatesTask = listenForTransactions()
        if isTestBuild && UserDefaults.standard.bool(forKey: testOverrideKey) {
            testOverrideEnabled = true
            hasUnlimited = true
        }
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

        storeUnlocked = unlocked
        testOverrideEnabled = isTestBuild && UserDefaults.standard.bool(forKey: testOverrideKey)
        let effectiveUnlocked = storeUnlocked || testOverrideEnabled

        hasUnlimited = effectiveUnlocked
        UserDefaults.standard.set(effectiveUnlocked, forKey: entitlementKey)
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

    var canUseTestOverride: Bool {
        isTestBuild
    }

    func toggleTestOverride() {
        setTestOverrideEnabled(!testOverrideEnabled)
    }

    func setTestOverrideEnabled(_ enabled: Bool) {
        guard isTestBuild else { return }
        UserDefaults.standard.set(enabled, forKey: testOverrideKey)
        testOverrideEnabled = enabled

        let effectiveUnlocked = storeUnlocked || testOverrideEnabled
        hasUnlimited = effectiveUnlocked
        UserDefaults.standard.set(effectiveUnlocked, forKey: entitlementKey)
    }

    private var isTestBuild: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
}
