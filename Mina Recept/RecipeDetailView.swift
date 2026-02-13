//
//  RecipeDetailView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-15.
//


import SwiftUI
import CoreData
import CloudKit


struct ShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}




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
    @State private var loadedImage: UIImage?
    @State private var didLoadImage = false
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var share: CKShare?
    @State private var container: CKContainer?
    //@State private var shareData: ShareData?
    // @State private var shareItem: ShareURLWrapper?
    @State private var shareItem: ShareItem?
    
    
    
    
    
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
    
    struct ActivityView: UIViewControllerRepresentable {
        var activityItems: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    // MARK: - Image loader
    // private var recipeImage: UIImage? {
    //    guard
    //       let filename = recipe.imageFilename,
    //      let image = FileHelper.loadImage(filename: filename)
    //  else { return nil }
    //   return image
    //  }
    private func loadImageIfNeeded() {
        guard
            !didLoadImage,
            let filename = recipe.imageFilename
        else { return }
        
        didLoadImage = true
        loadedImage = FileHelper.loadImage(filename: filename)
        
#if DEBUG
        print("✅ Bild laddad i RecipeDetailView")
#endif
        
    }
    private func shareRecipe() {
        
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "RecipeShare")
        record["title"] = recipe.title as CKRecordValue?
        record["instructions"] = recipe.instructions as CKRecordValue?
        
        if let image = loadedImage,
             let data = image.jpegData(compressionQuality: 0.8) {

             // let tempURL = FileManager.default.temporaryDirectory
               //   .appendingPathComponent(UUID().uuidString + ".jpg")
            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let fileURL = documents.appendingPathComponent("\(UUID().uuidString).jpg")


           // try? data.write(to: fileURL)
           // record["image"] = CKAsset(fileURL: fileURL)
            do {
                try data.write(to: fileURL)
                print("Image written to:", fileURL.path)
            } catch {
                print("WRITE FAILED:", error)
            }



          }
        
        database.save(record) { savedRecord, error in
            
            guard let savedRecord = savedRecord else { return }
            
            let recordName = savedRecord.recordID.recordName
            let deepLink = "minarecept://import?id=\(recordName)"
            
            DispatchQueue.main.async {
                
                var items: [Any] = []
                
                if let image = loadedImage {
                    items.append(image)
                }
                
                items.append(recipe.title ?? "")
                items.append(deepLink)
                
                self.shareItem = ShareItem(items: items)
                self.activeSheet = .share
            }
        }
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
                        // image: recipeImage,
                        image: loadedImage,
                        noImageText: L("no_image", languageManager)
                    )
                    
                    .onAppear {
                        loadImageIfNeeded()
                    }
                    
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
                            Text("\(L("portions", languageManager)): \(servings)")
                            Spacer()
                            Stepper("", value: $servings, in: 1...12)
                        }
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
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
            .scrollIndicators(.hidden)
            
      
            // MARK: - Toolbar
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                       Button(L("share", languageManager)) {
                        activeSheet = .share
                    
                        }

                      //  }
                        
                        
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
            
            // MARK: - Delete alert
            .confirmationDialog(
                L("delete_recipe_question", languageManager),
                isPresented: $showDeleteAlert,
                titleVisibility: .visible
            ) {
                Button(L("delete", languageManager), role: .destructive) {
                    context.delete(recipe)
                    try? context.save()
                    dismiss()
                }
                
                Button(L("cancel", languageManager), role: .cancel) {}
            }
            
            
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ActivityView(activityItems: [url])
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
                        // image: recipeImage,
                        image: loadedImage,
                        ingredients: recipe.ingredientArray.map {
                            PendingIngredient(
                                name: $0.name ?? "",
                                amount: $0.amount,
                                unit: $0.unit ?? ""
                            )
                        }
                        
                        
                    )
                }
            }
        }
    }
}
