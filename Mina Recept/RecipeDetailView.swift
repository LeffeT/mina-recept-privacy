//
//  RecipeDetailView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-15.
//


import SwiftUI
import CoreData
import CloudKit
import os


struct ShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct ServingsStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 0) {
            stepButton(systemName: "minus", isDisabled: value <= range.lowerBound) {
                value = max(range.lowerBound, value - 1)
            }

            Rectangle()
                .fill(theme.primaryTextColor.opacity(0.12))
                .frame(width: 1)

            stepButton(systemName: "plus", isDisabled: value >= range.upperBound) {
                value = min(range.upperBound, value + 1)
            }
        }
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.buttonBackground)
        )
    }

    private func stepButton(
        systemName: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .frame(width: 36, height: 30)
                .foregroundColor(
                    theme.primaryTextColor.opacity(isDisabled ? 0.35 : 1.0)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(systemName == "minus" ? "Minska" : "Öka")
    }
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
    @State private var lastLoadedFilename: String?
    @State private var selectedGroupIndex: Int = 0
    @State private var ingredientTabHeight: CGFloat = 120
    @State private var ingredientPageHeights: [Int: CGFloat] = [:]
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var share: CKShare?
    @State private var container: CKContainer?
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

    private struct IngredientGroup: Identifiable {
        let id: Int
        let title: String
        let ingredients: [IngredientEntity]
    }

    private struct IngredientPageHeightKey: PreferenceKey {
        static var defaultValue: [Int: CGFloat] = [:]

        static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
            value.merge(nextValue(), uniquingKeysWith: { _, new in new })
        }
    }

    private var ingredientGroups: [IngredientGroup] {
        let titles = [
            recipe.group1Title ?? "",
            recipe.group2Title ?? "",
            recipe.group3Title ?? ""
        ]

        let groups = (0..<3).compactMap { index -> IngredientGroup? in
            let items = recipe.ingredientArray.filter { $0.safeGroupIndex == index }
            if items.isEmpty {
                return nil
            }

            let rawTitle = titles.indices.contains(index) ? titles[index] : ""
            let title = rawTitle.isEmpty ? defaultGroupTitle(for: index) : rawTitle
            return IngredientGroup(id: index, title: title, ingredients: items)
        }

        if groups.isEmpty {
            return [
                IngredientGroup(
                    id: 0,
                    title: defaultGroupTitle(for: 0),
                    ingredients: []
                )
            ]
        }

        return groups
    }

    private func defaultGroupTitle(for index: Int) -> String {
        let base = L("ingredients", languageManager)
        return index == 0 ? base : "\(base) \(index + 1)"
    }

    private func loadImageIfNeeded() {
        guard let filename = recipe.imageFilename else {
            loadedImage = nil
            lastLoadedFilename = nil
            return
        }

        guard lastLoadedFilename != filename else { return }

        lastLoadedFilename = filename
        loadedImage = nil
        FileHelper.loadImageAsync(filename: filename) { image in
            guard lastLoadedFilename == filename else { return }
            loadedImage = image
        }
        
#if DEBUG
        AppLog.ui.debug("Image load requested in RecipeDetailView")
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

            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let fileURL = documents.appendingPathComponent("\(UUID().uuidString).jpg")

            do {
                try data.write(to: fileURL)
                AppLog.share.debug("Image written to \(fileURL.path, privacy: .private)")
            } catch {
                AppLog.share.error("Image write failed: \(error.localizedDescription, privacy: .public)")
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
                    .onChange(of: recipe.imageFilename) { _, _ in
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
                        // Portionsrad (överst)
                        HStack {
                            Text("\(L("serves", languageManager)): \(servings)")
                            Spacer()
                            ServingsStepper(
                                value: $servings,
                                range: 1...12,
                                theme: themeManager.currentTheme
                            )
                        }
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        Divider().opacity(0.2)

                        VStack(alignment: .leading, spacing: 8) {
                            TabView(selection: $selectedGroupIndex) {
                                ForEach(ingredientGroups) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(group.title)
                                            .font(.headline)
                                            .foregroundColor(
                                                themeManager.currentTheme.primaryTextColor.opacity(0.85)
                                            )

                                        if group.ingredients.isEmpty {
                                            Text(L("ingredients", languageManager))
                                                .foregroundColor(
                                                    themeManager.currentTheme.primaryTextColor.opacity(0.5)
                                                )
                                        } else {
                                            ForEach(group.ingredients, id: \.id) { ingredient in
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
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .background(
                                        GeometryReader { proxy in
                                            Color.clear.preference(
                                                key: IngredientPageHeightKey.self,
                                                value: [group.id: proxy.size.height]
                                            )
                                        }
                                    )
                                    .tag(group.id)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: max(ingredientTabHeight, 80), alignment: .leading)

                            if ingredientGroups.count > 1 {
                                HStack(spacing: 8) {
                                    ForEach(ingredientGroups) { group in
                                        Circle()
                                            .fill(
                                                selectedGroupIndex == group.id
                                                ? themeManager.currentTheme.primaryTextColor
                                                : themeManager.currentTheme.primaryTextColor.opacity(0.35)
                                            )
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 2)
                            }
                        }
                        .onAppear {
                            if let first = ingredientGroups.first {
                                selectedGroupIndex = first.id
                            }
                            if let height = ingredientPageHeights[selectedGroupIndex] {
                                ingredientTabHeight = height
                            }
                        }
                        .onChange(of: selectedGroupIndex) { _, newValue in
                            if let height = ingredientPageHeights[newValue] {
                                ingredientTabHeight = height
                            }
                        }
                        .onPreferenceChange(IngredientPageHeightKey.self) { values in
                            ingredientPageHeights.merge(values, uniquingKeysWith: { _, new in new })
                            if let height = ingredientPageHeights[selectedGroupIndex] {
                                ingredientTabHeight = height
                            }
                        }
                    }
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor)
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
                        image: loadedImage,
                        ingredients: recipe.ingredientArray.map {
                            PendingIngredient(
                                name: $0.name ?? "",
                                amount: $0.amount,
                                amountText: $0.amountText,
                                unit: $0.unit ?? "",
                                groupIndex: $0.safeGroupIndex
                            )
                        },
                        baseServings: Int(recipe.baseServings),
                        groupTitles: [
                            recipe.group1Title ?? "",
                            recipe.group2Title ?? "",
                            recipe.group3Title ?? ""
                        ]
                        
                        
                    )
                }
            }
        }
    }
}
