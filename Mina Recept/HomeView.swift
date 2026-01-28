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
import CoreData

struct HomeView: View {

    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager


    // 🔤 Sortera recept A–Ö via normaliserad sortTitle
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Recipe.sortTitle, ascending: true)
        ]
    )
    private var recipes: FetchedResults<Recipe>

    @State private var showingAdd = false
    
    
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
            print("✅ baseServings fixad")
        } catch {
            print("❌ Kunde inte spara:", error)
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
                                if let filename = recipe.imageFilename,
                                   let img = FileHelper.loadImage(filename: filename) {

                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipped()
                                        .cornerRadius(10)

                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.15))
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            Image(systemName: "fork.knife")
                                                .foregroundColor(.white.opacity(0.7))
                                        )
                                }

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
                        showingAdd = true
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
            // 🔧 Kör EN GÅNG för att fylla sortTitle på gamla recept
            .onAppear {
                print("DEBUG: HomeView visas")
                backfillSortTitlesIfNeeded()
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

