//
//  SharedRecipeLandingView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-31.
//


import SwiftUI
import CoreData

struct SharedRecipeLandingView: View {
    
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var purchaseManager: PurchaseManager

    @FetchRequest(sortDescriptors: [])
    private var recipes: FetchedResults<Recipe>

    let recipeID: String

    @Environment(\.dismiss) private var dismiss
  
    


    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var showPaywall = false

    private var isLocked: Bool {
        !purchaseManager.hasUnlimited &&
        recipes.count >= PurchaseManager.freeRecipeLimit
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {

                Text(L("import_recipe_title", languageManager))

                    .font(.title2)
                    .fontWeight(.semibold)

                Text(
                    L("import_recipe_question", languageManager)
                )

                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                if isImporting {
                    ProgressView().padding(.top, 10)
                }

                if showSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(L("import_recipe_success", languageManager))
                    }
                    .foregroundColor(.green)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.orange)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {

                    Button(L("cancel", languageManager)) {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)

                    Button(L("import", languageManager)) {
                        if isLocked {
                            showPaywall = true
                            return
                        }
                        importRecipe()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .disabled(isImporting || showSuccess)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .padding(30)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                freeLimit: PurchaseManager.freeRecipeLimit,
                currentCount: recipes.count
            )
        }
    }

    private func importRecipe() {
        guard !isImporting, !showSuccess else { return }

        isImporting = true
        errorMessage = nil

        ImportPayloadHandler.importPendingRecipe(
            recipeID: recipeID,

            onSuccess: {
                isImporting = false
                showSuccess = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            },

            onAlreadyImported: {
                isImporting = false
                errorMessage = L("import_recipe_already_imported", languageManager)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    dismiss()
                }
            },

            onMissingPayload: {
                isImporting = false
                errorMessage = L("import_recipe_missing_payload", languageManager)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    dismiss()
                }
            },

            onExpired: {
                isImporting = false
                errorMessage = L("import_recipe_expired", languageManager)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    dismiss()
                }
            }
        )
    }
}
