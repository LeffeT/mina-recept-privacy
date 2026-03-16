//
//  PaywallView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-27.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager

    let freeLimit: Int
    let currentCount: Int

    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var product: Product? {
        purchaseManager.products.first { $0.id == PurchaseManager.unlimitedProductID }
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(L("unlock_title", languageManager))
                    .font(.title.bold())
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor)
                    .multilineTextAlignment(.center)

                Text(
                    String(
                        format: L("unlock_message", languageManager),
                        freeLimit
                    )
                )
                .foregroundStyle(themeManager.currentTheme.primaryTextColor.opacity(0.8))
                .multilineTextAlignment(.center)

                if let product {
                    Text(product.displayPrice)
                        .font(.title2.bold())
                        .foregroundStyle(themeManager.currentTheme.primaryTextColor)
                } else if purchaseManager.isLoading {
                    ProgressView()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.orange)
                        .font(.footnote)
                }

                Button {
                    Task { await handlePurchase() }
                } label: {
                    paywallButtonLabel(L("unlock_cta", languageManager))
                        .padding(.vertical, 8)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isPurchasing)

                Button {
                    Task { await purchaseManager.restore() }
                } label: {
                    paywallButtonLabel(L("restore_purchases", languageManager))
                        .padding(.vertical, 8)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                }

                if purchaseManager.canUseTestOverride {
                    Button {
                        purchaseManager.toggleTestOverride()
                    } label: {
                        paywallButtonLabel(
                            purchaseManager.testOverrideEnabled
                                ? "Testläge: Av"
                                : "Testläge: Lås upp"
                        )
                        .padding(.vertical, 6)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .opacity(0.75)
                }

                Button {
                    dismiss()
                } label: {
                    paywallButtonLabel(L("close", languageManager))
                        .padding(.vertical, 8)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.currentTheme.cardBackground)
            )
            .padding(.horizontal, 28)
        }
        .task {
            await purchaseManager.loadProducts()
        }
        .onChange(of: purchaseManager.hasUnlimited) { _, unlocked in
            if unlocked {
                dismiss()
            }
        }
    }

    private func handlePurchase() async {
        errorMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        guard product != nil else {
            errorMessage = L("price_unavailable", languageManager)
            await purchaseManager.loadProducts()
            return
        }

        let success = await purchaseManager.purchase()
        if !success && !purchaseManager.hasUnlimited {
            errorMessage = L("purchase_failed", languageManager)
        }
    }

    private func paywallButtonLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }
}
