//
//  AddRecipeView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-13.
//

// AddRecipeView.swift
// Mina Recept

import SwiftUI
import CoreData
import UIKit

struct AddRecipeView: View {
    
    // MARK: - Prefill
    let prefilledTitle: String?
    let prefilledInstructions: String?
    let prefilledImageURL: URL?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    
    @StateObject private var languageManager = LanguageManager.shared
    
    // MARK: - Form state
    @State private var title: String = ""
    @State private var instructions: String = ""
    
    // Image
    @State private var pickedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    
    // Ingredients (TEMP)
    @State private var showUnitPicker = false
    @State private var tempIngredients: [TempIngredient] = []
    @State private var ingredientName = ""
    @State private var ingredientAmount = ""
    @State private var pulse = false
    @State private var hasSubmitted = false
    @State private var basePortions: String = "4"
    @State private var ingredientUnit: String = ""
    
    private let unitOptions = [
        "pcs", "g", "kg", "ml", "dl", "l", "tsp", "tbsp", "krm", "pinch"
    ]
    private let appGroupID = "group.se.leiftarvainen.minarecept"
    
    // MARK: - Field styling
    private let fieldHeight: CGFloat = 52
    
    private var editorBackground: Color {
        themeManager.currentTheme.cardBackground
    }
    private let formMaxWidth: CGFloat = 460
    
    private var imageHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 420 : 240
    }
    
    var portionsValue: Int {
        max(Int(basePortions) ?? 1, 1)
    }
    
    init(
        prefilledTitle: String? = nil,
        prefilledInstructions: String? = nil,
        prefilledImageURL: URL? = nil
    ) {
        self.prefilledTitle = prefilledTitle
        self.prefilledInstructions = prefilledInstructions
        self.prefilledImageURL = prefilledImageURL
    }
    
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 22) {
                    
                    headerImage
                    iconBar
                    form
                    
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear(perform: onAppearLoad)
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(source: .camera) { image in
                pickedImage = image
                showCamera = false
            }
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(source: .photoLibrary) { image in
                pickedImage = image
                showPhotoLibrary = false
            }
        }
    }
    
    // MARK: - Header Image
    private var headerImage: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let imageWidth = min(
                availableWidth - 32,
                UIDevice.current.userInterfaceIdiom == .pad ? 700 : 520
            )
            
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeManager.currentTheme.buttonBackground.opacity(0.6))
                    .frame(width: imageWidth, height: imageHeight)
                
                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 34))
                        Text(L("no_image", languageManager))
                            .font(.caption)
                    }
                    .foregroundColor(
                        themeManager.currentTheme.primaryTextColor.opacity(0.6)
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: imageHeight)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Icon Bar
    private var iconBar: some View {
        HStack(spacing: 28) {
            iconButton(systemName: "xmark.circle.fill", text: L("cancel", languageManager)) {
                dismiss()
            }
            iconButton(systemName: "camera.fill", text: L("take_photo", languageManager)) {
                showCamera = true
            }
            iconButton(systemName: "photo.on.rectangle", text: L("choose_image", languageManager)) {
                showPhotoLibrary = true
            }
            iconButton(
                systemName: "checkmark.circle.fill",
                text: L("save", languageManager),
                isDisabled: title.isEmpty
            ) {
                saveRecipe()
            }
        }
    }
    
    // MARK: - FORM
    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            
            Text(L("new_recipe", languageManager))
                .font(.largeTitle.bold())
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            label(L("title", languageManager))
            TextField(L("title_placeholder", languageManager), text: $title)
                .modifier(fieldStyle)
            // .tint(.white)
            
            //label(L("instructions", languageManager))
            // TextEditor(text: $instructions)
            //    .modifier(editorStyle)
            //   .tint(.white)
            
            label(L("portions", languageManager))
            
            TextField(L("portions", languageManager),
                      text: $basePortions,
            )
            .keyboardType(.numberPad)
            .tint(.white)
            .padding(12)
            .background(themeManager.currentTheme.buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            // INGREDIENT INPUT
            label(L("ingredients", languageManager))
            
            TextField(
                L("ingredient", languageManager),
                text: $ingredientName
            )
            .modifier(fieldStyle)
            
            //.tint(.white)
            
            TextField(
               L("amount", languageManager),
               text: $ingredientAmount
                
            )
            .keyboardType(.decimalPad)
            .modifier(fieldStyle)
            //.tint(.white)
            
            
            Menu {
                ForEach(unitOptions, id: \.self) { unit in
                    Button {
                        ingredientUnit = unit
                    } label: {
                        Text(L("unit.\(unit)", languageManager))
                    }
                }
            } label: {
                HStack {
                    Text(
                       // L("unit.pinch", languageManager)
                       ingredientUnit.isEmpty
                      ? L("unit", languageManager)
                      : L("unit.\(ingredientUnit)", languageManager)
                    )
                    .foregroundColor(
                    ingredientUnit.isEmpty
                     ? themeManager.currentTheme.buttonBackground
                    : themeManager.currentTheme.primaryTextColor
                        .opacity(ingredientUnit.isEmpty ? 0.9 : 1.5)
                   )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(
                    themeManager.currentTheme.primaryTextColor.opacity(0.7)
                    )
                }
                .padding(.horizontal, 16)
                .frame(height: fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.buttonBackground)
                )
            }
            .buttonStyle(.plain)
        
            var isValid: Bool {
                !ingredientName.isEmpty &&
                Double(ingredientAmount) != nil &&
                !ingredientUnit.isEmpty
            }
            
            // ✅ BUTTON – EXACTLY HERE
            Button(action: {
                hasSubmitted = true
                pulse = false
                addIngredient()
            }) {
                Text(L("add_ingredient", languageManager))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .opacity(
                isValid && !hasSubmitted
                ? (pulse ? 1.0 : 0.55)
                : 0.4
            )
            .scaleEffect(isValid && !hasSubmitted && pulse ? 1.03 : 0.8)
            .disabled(!isValid)
            .animation(
                isValid && !hasSubmitted
                ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                : .default,
                value: pulse
            )
            .buttonStyle(.plain)
            
            .onChange(of: isValid) {
                if isValid && !hasSubmitted {
                    pulse = false
                    DispatchQueue.main.async {
                        pulse = true
                    }
                } else {
                    pulse = false
                }
            }
            .onChange(of: ingredientName) {
                hasSubmitted = false
            }
            .onChange(of: ingredientAmount) {
                hasSubmitted = false
            }
            .onChange(of: ingredientUnit) {
                hasSubmitted = false
            }
            
            
            
            IngredientListView(
                ingredients: tempIngredients,
                themeManager: themeManager,
                languageManager: languageManager,
                
               // scale: 1.0,   // 👈 VIKTIGT
                onDelete: { ing in
                    tempIngredients.removeAll { $0.id == ing.id }
                }
                )
        
            
         
            label(L("instructions", languageManager))
            TextEditor(text: $instructions)
                .modifier(editorStyle)
               
        }
        .frame(maxWidth: 520)
       .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

            // MARK: - Actions
            private func addIngredient() {
                guard
                    !ingredientName.isEmpty,
                    let amount = Double(ingredientAmount)
                else { return }
                
                tempIngredients.append(
                    TempIngredient(
                        name: ingredientName,
                        amount: amount,
                        unit: ingredientUnit,
                        scalable: true,
                        pluralName: nil
                    )
                )
                
                ingredientName = ""
                ingredientAmount = ""
                ingredientUnit = ""
            }
            
            private func saveRecipe() {
                print("💾 saveRecipe called")
                let new = Recipe(context: context)
                new.id = UUID()
                new.title = title
                new.sortTitle = title.sortKey(locale: languageManager.locale)
                new.instructions = instructions
                new.date = Date()
                new.baseServings = Int16(portionsValue)
                //new.baseServings = 1
                
                
                for temp in tempIngredients {
                    let ing = IngredientEntity(context: context)
                    ing.id = UUID()
                    ing.name = temp.name
                    ing.amount = temp.amount
                    ing.unit = temp.unit
                    ing.scalable = temp.scalable
                    ing.pluralName = temp.pluralName
                    ing.recipe = new
                    
                }
                
                if let img = pickedImage {
                    let resized = img.normalizedAndResized(maxWidth: 1200, maxHeight: 800)
                    if let data = resized.jpegData(compressionQuality: 0.85) {
                        let filename = UUID().uuidString + ".jpg"
                        FileHelper.saveImageData(filename: filename, data: data)
                        new.imageFilename = filename
                    }
                }
                
                do {
                    try context.save()
                    dismiss()
                } catch {
                    print("❌ Kunde inte spara:", error)
                }
            }
            
            // MARK: - Helpers
            private func onAppearLoad() {
                if let prefilledTitle, title.isEmpty { title = prefilledTitle }
                if let prefilledInstructions, instructions.isEmpty { instructions = prefilledInstructions }
                
                if let url = prefilledImageURL {
                    loadImageFromURL(url)
                } else {
                    loadSharedImageIfExists()
                }
            }
            
            private func iconButton(
                systemName: String,
                text: String,
                isDisabled: Bool = false,
                action: @escaping () -> Void
            ) -> some View {
                Button(action: action) {
                    VStack(spacing: 6) {
                        Image(systemName: systemName).font(.system(size: 22))
                        Text(text).font(.caption)
                    }
                    .foregroundColor(
                        themeManager.currentTheme.primaryTextColor.opacity(isDisabled ? 0.4 : 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
            
            private func label(_ text: String) -> some View {
                Text(text)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            private var fieldStyle: some ViewModifier {
                FieldStyle(theme: themeManager)
            }
            
            private var editorStyle: some ViewModifier {
                EditorStyle(theme: themeManager)
            }
            
            private func loadImageFromURL(_ url: URL) {
                guard
                    url.isFileURL,
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data)
                else { return }
                pickedImage = image
            }
            
            private func loadSharedImageIfExists() {
                guard
                    let defaults = UserDefaults(suiteName: appGroupID),
                    let urlString = defaults.string(forKey: "sharedImageURL"),
                    let url = URL(string: urlString),
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data)
                else { return }
                pickedImage = image
            }
        }
        
        // MARK: - TempIngredient
        struct TempIngredient: Identifiable {
            let id = UUID()
            let name: String
            let amount: Double
            let unit: String
            let scalable: Bool
            let pluralName: String?
        }
 
