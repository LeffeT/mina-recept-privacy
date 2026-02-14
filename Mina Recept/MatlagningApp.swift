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
    
    
    
    init() {
        if let url = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.se.leiftarvainen.minarecept") {
            AppLog.cloudkit.info("iCloud container: \(url.path, privacy: .private)")
        } else {
            AppLog.cloudkit.error("iCloud container not available")
        }

        CloudKitService.shared.cleanupExpiredSharesForCurrentUser()
    }

 
    @State private var presentedRecipeID: String?

    @UIApplicationDelegateAdaptor(AppDelegate.self)
       var appDelegate

    // 🎨 Tema
    @StateObject private var themeManager = ThemeManager()

    // 🌍 Språk (NY – OBLIGATORISK)
    @StateObject private var languageManager = LanguageManager.shared

    // 🔗 Deep link manager
    @StateObject private var deepLinkManager = DeepLinkManager()
    @StateObject private var cloudSyncStatus = CloudSyncStatus()

    // 💾 Core Data – EN källa
    let container = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
         
            NavigationStack {
                StartView()
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
                    get: { presentedRecipeID != nil },
                    set: { if !$0 { presentedRecipeID = nil } }
                )
            ) {
                if let recipeID = presentedRecipeID {
                    SharedRecipeLandingView(recipeID: recipeID)
                        .environmentObject(languageManager)
            #if DEBUG
                        .onAppear {
                            AppLog.share.debug("Presenting SharedRecipeLandingView for recipeID: \(recipeID, privacy: .public)")
                        }
            #endif
                }
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
