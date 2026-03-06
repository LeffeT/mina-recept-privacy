//
//  HomeView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-01.
//


//
//  HomeView.swift
//  Mina Recept
//

import SwiftUI
import Foundation
import CoreData
import os

struct HomeView: View {

    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var cloudSyncStatus: CloudSyncStatus
    @EnvironmentObject var purchaseManager: PurchaseManager


    // 🔤 Sortera recept A–Ö via normaliserad sortTitle
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Recipe.sortTitle, ascending: true)
        ]
    )
    private var recipes: FetchedResults<Recipe>

    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var didScheduleBackgroundTasks = false

    private var isLocked: Bool {
        !purchaseManager.hasUnlimited &&
        recipes.count >= PurchaseManager.freeRecipeLimit
    }
    
    
    func fixBaseServings(
        context: NSManagedObjectContext,
        recipes: FetchedResults<Recipe>
    ) {
        for recipe in recipes {
            if recipe.baseServings == 0 {
                recipe.baseServings = 1
            }
        }

        do {
            try context.save()
            #if DEBUG
            AppLog.storage.debug("baseServings fixad")
            #endif
        } catch {
            #if DEBUG
            AppLog.storage.error("Kunde inte spara: \(error.localizedDescription, privacy: .public)")
            #endif
        }
    }


    var body: some View {
        NavigationStack {
            ZStack {
                // 🌈 Tema-bakgrund
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea()

                List {
                    ForEach(recipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            HStack(spacing: 12) {

                                // 🖼 Bild
                                RecipeRowImage(filename: recipe.imageFilename)

                                // 📝 Text
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.title ?? L("untitled", languageManager))

                                        .font(.headline)
                                        .foregroundColor(
                                            themeManager.currentTheme.primaryTextColor
                                        )

                                    if let date = recipe.date {
                                        Text(date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(
                                                themeManager.currentTheme.primaryTextColor.opacity(0.7)
                                            )
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(
                L("recipes", languageManager)
            )

            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if isLocked {
                            showingPaywall = true
                        } else {
                            showingAdd = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(
                                themeManager.currentTheme.primaryTextColor
                            )
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddRecipeView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(
                    freeLimit: PurchaseManager.freeRecipeLimit,
                    currentCount: recipes.count
                )
            }
            // 🔧 Kör EN GÅNG för att fylla sortTitle på gamla recept
            .onAppear {
              #if DEBUG
                AppLog.ui.debug("HomeView visas")
              #endif
                backfillSortTitlesIfNeeded()
                scheduleBackgroundTasksIfNeeded()
            }
            .onChange(of: cloudSyncStatus.state) { _, newValue in
                guard newValue == .idle else { return }
                flushPendingImagesIfPossible()
            }
            .onChange(of: languageManager.selectedLanguage) { _, _ in
                DemoRecipeSeeder.seedIfNeeded(
                    container: CoreDataStack.shared.container,
                    languageManager: languageManager
                )
            }
        }
    }

    // 🔁 Fyll i sortTitle för gamla recept (körs säkert flera gånger)
    private func backfillSortTitlesIfNeeded() {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let recipes = (try? context.fetch(request)) ?? []

        var didChange = false

        for recipe in recipes {
            if recipe.sortTitle == nil || recipe.sortTitle!.isEmpty {
                let title = recipe.title ?? ""
                recipe.sortTitle = title.sortKey(locale: LanguageManager.shared.locale)

                didChange = true
            }
        }

        if didChange {
            try? context.save()
        }
    }

    private func scheduleBackgroundTasksIfNeeded() {
        guard !didScheduleBackgroundTasks else { return }
        didScheduleBackgroundTasks = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            DemoRecipeSeeder.seedIfNeeded(
                container: CoreDataStack.shared.container,
                languageManager: languageManager
            )
        }

        flushPendingImagesIfPossible()

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            CloudKitService.shared.cleanupExpiredSharesForCurrentUser()
        }
    }

    private func flushPendingImagesIfPossible() {
        guard FileManager.default.ubiquityIdentityToken != nil else { return }
        DispatchQueue.global(qos: .utility).async {
            FileHelper.flushPendingImagesIfPossible()
        }
    }


    // 🗑 Radera recept + bild
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let recipe = recipes[index]

            if let filename = recipe.imageFilename {
                FileHelper.deleteImage(filename: filename)
            }

            context.delete(recipe)
        }

        try? context.save()
    }
}

private struct RecipeRowImage: View {
    let filename: String?

    @EnvironmentObject var themeManager: ThemeManager
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.cardBackground)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(
                                themeManager.currentTheme.primaryTextColor.opacity(0.7)
                            )
                    )
            }
        }
        .frame(width: 64, height: 64)
        .clipped()
        .cornerRadius(10)
        .onAppear { loadImageIfNeeded() }
        .onChange(of: filename) { _, _ in loadImageIfNeeded() }
    }

    private func loadImageIfNeeded() {
        image = nil
        guard let filename else { return }
        FileHelper.loadImageAsync(filename: filename) { loaded in
            image = loaded
        }
    }
}
