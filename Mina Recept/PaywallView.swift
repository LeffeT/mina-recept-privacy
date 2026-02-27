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
                    Text(L("unlock_cta", languageManager))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeManager.currentTheme.buttonBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isPurchasing || product == nil)

                Button {
                    Task {
                        await purchaseManager.restore()
                    }
                } label: {
                    Text(L("restore_purchases", languageManager))
                        .font(.subheadline)
                }
                .foregroundStyle(themeManager.currentTheme.primaryTextColor.opacity(0.85))

                Button(L("close", languageManager)) {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.primaryTextColor.opacity(0.7))
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

        let success = await purchaseManager.purchase()
        if !success && !purchaseManager.hasUnlimited {
            errorMessage = L("purchase_failed", languageManager)
        }
    }
}
