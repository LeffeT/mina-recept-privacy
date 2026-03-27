//
//  MatlagningApp.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-01.
//


//
//  MatlagningApp.swift
//  Mina Recept
//
//  Deep link: minarecept://import?id=...
//

import SwiftUI
import CoreData
import os

@main
struct MatlagningApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var presentedRecipeID: String?
    @State private var didRunStartupTasks = false

    @UIApplicationDelegateAdaptor(AppDelegate.self)
       var appDelegate

    // 🎨 Tema
    @StateObject private var themeManager = ThemeManager()

    // 🌍 Språk (NY – OBLIGATORISK)
    @StateObject private var languageManager = LanguageManager.shared

    // 🔗 Deep link manager
    @StateObject private var deepLinkManager = DeepLinkManager()
    @StateObject private var cloudSyncStatus = CloudSyncStatus()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var cookingModeManager = CookingModeManager()
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var recipeBackupManager = RecipeBackupManager(
        container: CoreDataStack.shared.container
    )

    private var container: NSPersistentCloudKitContainer {
        coreDataStack.container
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea()

                if coreDataStack.isLoaded {
                    NavigationStack {
                        StartView()
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(themeManager.currentTheme.primaryTextColor)
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            // 🌍 Environment
            .environment(
                \.managedObjectContext,
                container.viewContext
            )
            .environmentObject(themeManager)
            .environmentObject(languageManager)   // ✅ VIKTIG RAD
            .environmentObject(deepLinkManager)
            .environmentObject(cloudSyncStatus)
            .environmentObject(purchaseManager)
            .environmentObject(cookingModeManager)

            // 📬 Tar emot deep links
            .onOpenURL { url in
                #if DEBUG
                AppLog.share.debug("onOpenURL triggered")
                AppLog.share.debug("URL received: \(url.absoluteString, privacy: .private)")
                AppLog.share.debug("Incoming URL: \(String(describing: url), privacy: .private)")
                #endif
                deepLinkManager.handle(url)
            }
            .onChange(of: deepLinkManager.pendingRecipeID) { _, newID in
                guard let id = newID else { return }

                presentedRecipeID = id        // kopiera till UI-state
                deepLinkManager.clear()       // konsumera direkt
         

            }
            // 📥 Visar import-landing när recept kommer via deep link
            .sheet(
                isPresented: Binding(
                    get: { coreDataStack.isLoaded && presentedRecipeID != nil },
                    set: { if !$0 { presentedRecipeID = nil } }
                )
            ) {
                if let recipeID = presentedRecipeID {
                    SharedRecipeLandingView(recipeID: recipeID)
                        .environment(\.managedObjectContext, container.viewContext)
                        .environmentObject(themeManager)
                        .environmentObject(languageManager)
                        .environmentObject(purchaseManager)
            #if DEBUG
                        .onAppear {
                            AppLog.share.debug("Presenting SharedRecipeLandingView for recipeID: \(recipeID, privacy: .public)")
                        }
            #endif
                }
            }
            .onAppear {
                coreDataStack.loadIfNeeded()
                cookingModeManager.setAppActive(scenePhase == .active)
                runStartupTasksIfNeeded()
            }
            .onChange(of: coreDataStack.isLoaded) { _, _ in
                runStartupTasksIfNeeded()
            }
            .onChange(of: scenePhase) { _, newValue in
                cookingModeManager.setAppActive(newValue == .active)
                guard coreDataStack.isLoaded else { return }
                if newValue == .active {
                    cloudSyncStatus.refresh()
                    recipeBackupManager.refreshBackup()
                    recipeBackupManager.handleCloudStateChange(
                        cloudSyncStatus.state,
                        locale: languageManager.locale
                    )
                }
            }
            .onChange(of: cloudSyncStatus.state) { _, newValue in
                recipeBackupManager.handleCloudStateChange(
                    newValue,
                    locale: languageManager.locale
                )
            }


    }
    }

    // MARK: - Binding för sheet(item:)
    private var pendingRecipeBinding: Binding<PendingRecipe?> {
        Binding(
            get: {
                if let id = deepLinkManager.pendingRecipeID {
                    #if DEBUG
                    AppLog.share.debug("pendingRecipeID detected: \(id, privacy: .public)")
                    #endif
                    return PendingRecipe(id: id)
                }
                return nil
            },
            set: { newValue in
                if newValue == nil {
                    #if DEBUG
                    AppLog.share.debug("Clearing pendingRecipeID")
                    #endif
                    deepLinkManager.clear()
                }
            }
        )
    }
}

// MARK: - Hjälpmodell för SwiftUI sheet(item:)
struct PendingRecipe: Identifiable {
    let id: String
}

private extension MatlagningApp {
    func runStartupTasksIfNeeded() {
        guard coreDataStack.isLoaded, !didRunStartupTasks else { return }
        didRunStartupTasks = true

        cloudSyncStatus.refresh()
        recipeBackupManager.refreshBackup()
        recipeBackupManager.handleCloudStateChange(
            cloudSyncStatus.state,
            locale: languageManager.locale
        )
    }
}
