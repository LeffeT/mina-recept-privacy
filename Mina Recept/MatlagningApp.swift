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
                print("📬 onOpenURL triggered")
                print("➡️ URL received:", url.absoluteString)
                deepLinkManager.handle(url)
            }

            // 📥 Visar import-landing när recept kommer via deep link
            .sheet(item: pendingRecipeBinding) { pending in
                SharedRecipeLandingView(recipeID: pending.id)
                    .environmentObject(languageManager)   // ⭐ DENNA RAD
                    .onAppear {
                        print("📄 Presenting SharedRecipeLandingView for recipeID:", pending.id)
                    }
            }
        }
    }

    // MARK: - Binding för sheet(item:)
    private var pendingRecipeBinding: Binding<PendingRecipe?> {
        Binding(
            get: {
                if let id = deepLinkManager.pendingRecipeID {
                    print("🟡 pendingRecipeID detected:", id)
                    return PendingRecipe(id: id)
                }
                return nil
            },
            set: { newValue in
                if newValue == nil {
                    print("🧹 Clearing pendingRecipeID")
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
