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

@main
struct MatlagningApp: App {
    
    
    
    init() {
        if let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            print("✅ iCloud container:", url)
        } else {
            print("❌ iCloud container NOT available")
        }
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

            // 📬 Tar emot deep links
            .onOpenURL { url in
                #if DEBUG
                print("📬 onOpenURL triggered")
                print("➡️ URL received:", url.absoluteString)
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
                            print("📄 Presenting SharedRecipeLandingView for recipeID:", recipeID)
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
                    print("🟡 pendingRecipeID detected:", id)
                    #endif
                    return PendingRecipe(id: id)
                }
                return nil
            },
            set: { newValue in
                if newValue == nil {
                    #if DEBUG
                    print("🧹 Clearing pendingRecipeID")
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
