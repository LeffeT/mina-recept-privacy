//
//  RecipeDetailView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-15.
//


import SwiftUI
import CoreData

struct RecipeDetailView: View {
    
    // MARK: - Dependencies
    @ObservedObject var recipe: Recipe
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    
    // MARK: - State
    @State private var showDeleteAlert = false
    @State private var servings: Int
    @State private var activeSheet: ActiveSheet?
    
    // MARK: - Init
    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: max(1, Int(recipe.baseServings)))
    }
    
    // MARK: - Sheets
    enum ActiveSheet: Identifiable {
        case edit
        case share
        var id: Int { hashValue }
    }
    
    // MARK: - Image loader
    private var recipeImage: UIImage? {
        guard
            let filename = recipe.imageFilename,
            let image = FileHelper.loadImage(filename: filename)
        else { return nil }
        return image
    }
    
    // MARK: - Layout
    private let readableContentWidth: CGFloat = 600
    
    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    
                    // MARK: - Bild
                    RecipeImageView(
                        image: recipeImage,
                        noImageText: L("no_image", languageManager)
                    )
                    
                    // MARK: - Titel
                    Text(recipe.title ?? L("untitled", languageManager))
                        .font(.largeTitle.bold())
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    // MARK: - Kort: portioner + ingredienser
                    
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Portionsrad
                        HStack {
                            Text("\(L("servings", languageManager)): \(servings)")
                            Spacer()
                            Stepper("", value: $servings, in: 1...12)
                        }
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        // Hjälptext
                      //  Text("🔁 = ändras med portioner")
                         //   .font(.caption)
                         //   .foregroundStyle(Color.white)
                        
                        // Ingredienslista
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.ingredientArray, id: \.id) { ingredient in
                                IngredientRowView(
                                    ingredient: ingredient,
                                    servings: servings,
                                    baseServings: Int(recipe.baseServings),
                                    themeManager: themeManager,
                                    languageManager: languageManager
                                )
                            }
                        }
                    }
                    .foregroundStyle(Color.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(themeManager.currentTheme.cardBackground)
                    )
                    
                    
                    
                    
                    // MARK: - Instruktioner
                    if let instructions = recipe.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {

                            Text(L("instructions", languageManager))
                                .font(.headline)
                                .foregroundColor(
                                    themeManager.currentTheme.primaryTextColor.opacity(0.85)
                                )

                            Divider().opacity(0.2)

                            Text(instructions)
                                .foregroundColor(
                                    themeManager.currentTheme.primaryTextColor.opacity(0.9)
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    themeManager.currentTheme.primaryTextColor.opacity(0.06)
                                )
                        )
                    }
                }
                .frame(maxWidth: readableContentWidth)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        // MARK: - Toolbar
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(L("share", languageManager)) {
                        activeSheet = .share
                    }
                    
                    Button(L("edit", languageManager)) {
                        activeSheet = .edit
                    }
                    
                    Button(L("delete", languageManager), role: .destructive) {
                        showDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        // MARK: - Sheets
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                EditRecipeView(recipe: recipe)
            case .share:
                ShareSheet(
                    title: recipe.title ?? "",
                    instructions: recipe.instructions ?? "",
                    image: recipeImage,
                    ingredients: recipe.ingredientArray.map {
                        PendingIngredient(
                            name: $0.name ?? "",
                            amount: $0.amount,
                            unit: $0.unit ?? ""
                        )
                    }
                )
                
                // MARK: - Delete alert
                .alert(
                    L("delete_recipe_question", languageManager),
                    isPresented: $showDeleteAlert
                ) {
                    Button(L("delete", languageManager), role: .destructive) {
                        context.delete(recipe)
                        try? context.save()
                        dismiss()
                    }
                    Button(L("cancel", languageManager), role: .cancel) {}
                }
            }
        }
    }
}

