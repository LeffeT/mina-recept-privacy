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
    @State private var didScheduleStartupLoadingTimeout = false
    @State private var startupLoadingTimedOut = false
    @State private var isStartupLoading = false
    @State private var hasCompletedInitialLoad = false
    @State private var hasRequestedStartupDemoSeed = false
    @State private var loadingSettleID = UUID()
    @State private var demoSeedScheduleID = UUID()

    private var isLocked: Bool {
        !purchaseManager.hasUnlimited &&
        recipes.count >= PurchaseManager.freeRecipeLimit
    }

    private var navigationBarColorScheme: ColorScheme {
        themeManager.currentTheme.primaryTextColor == .black ? .light : .dark
    }

    private var shouldShowStartupLoadingOverlay: Bool {
        isStartupLoading && !startupLoadingTimedOut && !hasCompletedInitialLoad
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
        ZStack {
            // 🌈 Tema-bakgrund
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()

            List {
                ForEach(recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeListRow(recipe: recipe)
                    }
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .opacity(shouldShowStartupLoadingOverlay ? 0.001 : 1)
            .allowsHitTesting(!shouldShowStartupLoadingOverlay)

            if shouldShowStartupLoadingOverlay {
                loadingOverlay
            }
        }
        .navigationTitle(
            L("recipes", languageManager)
        )
        .toolbarBackground(themeManager.currentTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(navigationBarColorScheme, for: .navigationBar)
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
            scheduleStartupLoadingTimeoutIfNeeded()
            beginStartupLoadingIfNeeded()
            scheduleDemoSeedIfNeeded()
        }
        .onChange(of: cloudSyncStatus.state) { _, newValue in
            if newValue == .idle {
                // Efter iCloud-sync kan sortTitle saknas på importerade recept.
                backfillSortTitlesIfNeeded()
                flushPendingImagesIfPossible()
            }

            if newValue == .unavailable {
                startupLoadingTimedOut = true
                isStartupLoading = false
                hasCompletedInitialLoad = true
            }

            beginStartupLoadingIfNeeded()
            scheduleDemoSeedIfNeeded()
        }
        .onChange(of: cloudSyncStatus.isCheckingAvailability) { _, _ in
            beginStartupLoadingIfNeeded()
            scheduleDemoSeedIfNeeded()
        }
        .onChange(of: languageManager.selectedLanguage) { _, _ in
            // Språkbyte ska inte skriva om recept eller trigga iCloud-sync.
        }
        .onChange(of: recipes.count) { _, newCount in
            if newCount > 0 {
                hasRequestedStartupDemoSeed = true
            }
            if newCount > 0 || shouldShowStartupLoadingOverlay {
                beginStartupLoadingIfNeeded()
            }
            scheduleDemoSeedIfNeeded()
        }
    }

    // 🔁 Fyll i sortTitle för gamla/inkorrekta recept (körs säkert flera gånger)
    private func backfillSortTitlesIfNeeded() {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let recipes = (try? context.fetch(request)) ?? []

        var didChange = false

        for recipe in recipes {
            let title = recipe.title ?? ""
            let expectedSortTitle = title.sortKey(locale: languageManager.locale)
            if recipe.sortTitle != expectedSortTitle {
                recipe.sortTitle = expectedSortTitle
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

        flushPendingImagesIfPossible()

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            CloudKitService.shared.cleanupExpiredSharesForCurrentUser()
        }
    }

    private func scheduleStartupLoadingTimeoutIfNeeded() {
        guard !didScheduleStartupLoadingTimeout else { return }
        didScheduleStartupLoadingTimeout = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 25.0) {
            startupLoadingTimedOut = true
            isStartupLoading = false
            hasCompletedInitialLoad = true
        }
    }

    private func beginStartupLoadingIfNeeded() {
        guard !hasCompletedInitialLoad else {
            isStartupLoading = false
            return
        }

        guard !startupLoadingTimedOut else {
            isStartupLoading = false
            return
        }

        guard FileHelper.isICloudAvailable() else {
            isStartupLoading = false
            return
        }

        let shouldBeginLoading =
            isStartupLoading ||
            (recipes.isEmpty && (
                cloudSyncStatus.isCheckingAvailability ||
                cloudSyncStatus.state == .syncing ||
                cloudSyncStatus.lastSyncDate == nil
            ))

        guard shouldBeginLoading else {
            hasCompletedInitialLoad = true
            isStartupLoading = false
            return
        }

        isStartupLoading = true

        let settleID = UUID()
        loadingSettleID = settleID

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard loadingSettleID == settleID else { return }

            if startupLoadingTimedOut || cloudSyncStatus.state == .unavailable {
                isStartupLoading = false
                hasCompletedInitialLoad = true
                return
            }

            if cloudSyncStatus.isCheckingAvailability || cloudSyncStatus.state == .syncing {
                beginStartupLoadingIfNeeded()
                return
            }

            hasCompletedInitialLoad = true
            isStartupLoading = false
        }
    }

    private func scheduleDemoSeedIfNeeded() {
        guard !hasRequestedStartupDemoSeed else { return }
        guard recipes.isEmpty else { return }
        let scheduleID = UUID()
        demoSeedScheduleID = scheduleID

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard demoSeedScheduleID == scheduleID else { return }
            guard !hasRequestedStartupDemoSeed else { return }
            guard recipes.isEmpty else { return }
            guard !cloudSyncStatus.isCheckingAvailability else { return }
            guard cloudSyncStatus.state != .syncing else { return }

            hasRequestedStartupDemoSeed = true
            DemoRecipeSeeder.seedIfNeeded(
                container: CoreDataStack.shared.container,
                languageManager: languageManager
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                beginStartupLoadingIfNeeded()
            }
        }
    }

    private func flushPendingImagesIfPossible() {
        guard FileHelper.isICloudAvailable() else { return }
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

    private var loadingOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(themeManager.currentTheme.accentColor)
                    .scaleEffect(1.15)

                Text(L("loading_recipes_title", languageManager))
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

                Text(L("loading_recipes_message", languageManager))
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(
                        themeManager.currentTheme.primaryTextColor.opacity(0.75)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeManager.currentTheme.cardBackground.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        themeManager.currentTheme.primaryTextColor.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 28)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}

private struct RecipeListRow: View {
    @ObservedObject var recipe: Recipe

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        HStack(spacing: 12) {
            RecipeRowImage(filename: recipe.imageFilename)
                .id(recipe.imageFilename ?? "recipe-row-placeholder")

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title ?? L("untitled", languageManager))
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

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
