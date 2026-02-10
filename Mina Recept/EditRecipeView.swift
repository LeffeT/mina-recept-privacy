//
//  EditRecipeView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-12.
//

//
//  EditRecipeView.swift
//  Mina Recept
//

import SwiftUI
import CoreData
import PhotosUI

struct EditRecipeView: View {
    
    @ObservedObject var recipe: Recipe
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var title: String = ""
    @State private var instructions = ""
    @State private var servings: Int = 1
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCamera = false
    //@State private var newName = ""
    @State private var ingredient = ""
    @State private var ingredientName: String = ""
    @State private var ingredientAmount: String = ""
    //@State private var newAmount = ""
    @State private var amount = ""
    @State private var unit = ""
    @State private var newUnit = ""
    @State private var showAddIngredient = false
    @State private var pulse = false
    @State private var hasSubmitted = false
    @State private var ingredientUnit: String = ""
    //@State private var tempIngredients: [TempIngredient] = []
    @FetchRequest private var ingredients: FetchedResults<IngredientEntity>
    private let unitOptions = [
        "pcs", "g", "kg", "ml", "dl", "l", "tsp", "tbsp", "krm", "pinch", "clove", "slice", "cl", "leaf", "package", "stalk", "can", "bunch"
    ]
    
    //Mark:
   var isValid: Bool {
        !ingredientName.isEmpty &&
        !ingredientUnit.isEmpty &&
        IngredientFormatter.parseAmount(
            ingredientAmount,
            locale: languageManager.locale
        ) != nil
    }
    
    // MARK: - Layout (samma filosofi som DetailView)
    private let fieldHeight: CGFloat = 52
    private let formMaxWidth: CGFloat = 460
    
    private var imageHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 420 : 240
    }
    private var destructiveColor: Color {
        themeManager.currentTheme.destructiveColor
    }// portionsräknare
    private var originalServingsText: String {
        "\(L("portions", languageManager)) \(recipe.baseServings)"
    }
    private var fieldStyle: some ViewModifier {
        FieldStyle(theme: themeManager)
    }
        private func loadIngredientForEdit(_ ingredient: IngredientEntity) {
          ingredientName = ingredient.name ?? ""
          ingredientAmount = ingredient.amount.cleanString
            ingredientUnit = unitKey(fromLocalized: ingredient.unit ?? "")
      }
   
    
    init(recipe: Recipe) {
        self.recipe = recipe

        _ingredients = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(
                    keyPath: \IngredientEntity.createdAt,
                    ascending: true
                )
            ],
            predicate: NSPredicate(
                format: "recipe == %@",
                recipe
            )
        )
    }


    
    // MARK: - UI helpers  ← ✅ HÄR
    @ViewBuilder
    func themedTextField(
        _ key: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(L(key, languageManager), text: text)
            .keyboardType(keyboard)
            .tint(themeManager.currentTheme.primaryTextColor)
            .padding(12)
            .background(themeManager.currentTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }
    @ViewBuilder
    func themedTextAction(
        _ key: String,
        systemImage: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        
        Button(action: action) {
            
            Label(
                L(key, languageManager),
                systemImage: systemImage
            )
            .font(.headline)
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
            // .padding(.vertical, 10)
        }
        .buttonStyle(.plain)   // ⬅️ VIKTIGAST
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
    }
    
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 22) {
                    
                    // MARK: - Bild
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
                    
                    
                    
                    
                    // MARK: - Ikonknappar
                    HStack(spacing: 28) {
                        
                        iconButton(
                            systemName: "xmark.circle.fill",
                            text: L("cancel", languageManager)
                        ) {
                            dismiss()
                        }
                        
                        PhotosPicker(
                            selection: $pickedItem,
                            matching: .images
                        ) {
                            iconLabel(
                                systemName: "photo.on.rectangle",
                                text: L("change_image", languageManager)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        iconButton(
                            systemName: "camera.fill",
                            text: L("take_photo", languageManager)
                        ) {
                            showCamera = true
                        }
                        
                        iconButton(
                            systemName: "checkmark.circle.fill",
                            text: L("save", languageManager),
                            isDisabled: title.isEmpty
                        ) {
                            save()
                        }
                    }
                    
                    // MARK: - Rubrik + redigera ingredienser
                    Text(L("edit_recipe", languageManager))
                        .tint(.white)          // 👈 markören
                        .font(.largeTitle.bold())
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    Text(originalServingsText)
                        .font(.subheadline)
                        .foregroundColor(
                            themeManager.currentTheme.primaryTextColor.opacity(0.7)
                        )
                    
                    // MARK: - FORMULÄR (titel + ingredienser)
                    VStack(alignment: .leading, spacing: 12) {
                        
                        // Titel
                        label(L("title", languageManager))
                        TextField(L("title_placeholder", languageManager), text: $title)
                            .modifier(fieldStyle)
                            .tint(.white)
                        
                        // Recept
                        IngredientFormSection(
                            ingredientName: $ingredientName,
                            ingredientAmount: $ingredientAmount,
                            ingredientUnit: $ingredientUnit,
                            themeManager: themeManager,
                            languageManager: languageManager,
                            unitOptions: unitOptions,
                            isValid: isValid,
                            hasSubmitted: $hasSubmitted,
                            pulse: $pulse,
                            addIngredient: addIngredient,
                            deleteIngredient: deleteIngredient,
                            loadIngredientForEdit: loadIngredientForEdit, // ✅ VIKTIG
                            recipe: recipe,
                            destructiveColor: destructiveColor
                        )
                        
                        
                        label(L("instructions", languageManager))
                        
                    }
                    .padding(.top, 8)
                    
                    
                    TextEditor(text: $instructions)
                    
                        .tint(.white)          // 👈 markören
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .padding(12)
                        .frame(minHeight: 220)
                        .background(editorBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(false)   // ✅ scrollar när man skriver
                }
                .frame(maxWidth: formMaxWidth)          // ✅ samma bredd för allt
                .frame(maxWidth: .infinity)              // ✅ centrerad kolumn
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        
        .scrollIndicators(.hidden)
            
            
     
        
        .onAppear {
            title = recipe.title ?? ""
            instructions = recipe.instructions ?? ""
            // 👇 detta saknas
              ingredientName = ""
              ingredientAmount = ""
              ingredientUnit = ""
            
            if let filename = recipe.imageFilename {
                pickedImage = FileHelper.loadImage(filename: filename)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(source: .camera) { image in
                pickedImage = image
                showCamera = false
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = image
                }
            }
        }
    }// Här Stängs body <----
 
   
    
    //private func loadIngredientForEdit(_ ingredient: IngredientEntity) {
     //   ingredientName = ingredient.name ?? ""
     //   ingredientAmount = ingredient.amount.cleanString
    //    ingredientUnit = unitKey(fromLocalized: ingredient.unit ?? "")
// }
    // MARK: - UI helpers (orörda)
    
    private func iconButton(
        systemName: String,
        text: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 22))
                Text(text)
                    .font(.caption)
            }
            .foregroundColor(
                themeManager.currentTheme.primaryTextColor
                    .opacity(isDisabled ? 0.4 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    private func iconLabel(
        systemName: String,
        text: String
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 22))
            Text(text)
                .font(.caption)
        }
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }
    
    private func label(_ text: String) -> some View {
        Text(text)
            .foregroundColor(themeManager.currentTheme.primaryTextColor.opacity(0.85))
    }
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(themeManager.currentTheme.buttonBackground.opacity(0.9))
    }
    
    private var editorBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(themeManager.currentTheme.buttonBackground.opacity(0.45))
    }
    private func addIngredient() {
        guard
            !ingredientName.isEmpty,
            !ingredientUnit.isEmpty,
            let value = IngredientFormatter.parseAmount(
                ingredientAmount,
                locale: languageManager.locale
            )
        else { return }

        let ing = IngredientEntity(context: context)
        ing.id = UUID()
        ing.name = ingredientName
        ing.amount = value
        ing.unit = ingredientUnit
        ing.scalable = true
        ing.recipe = recipe
        ing.createdAt = Date()

        try? context.save()

        ingredientName = ""
        ingredientAmount = ""
        ingredientUnit = ""
        hasSubmitted = false
    }




    private func deleteIngredient(_ ingredient: IngredientEntity) {
        context.delete(ingredient)
        try? context.save()
    }
    
    // MARK: - Save (orörd)
    
    private func save() {
        recipe.title = title
        recipe.instructions = instructions
        
        if let img = pickedImage {
            let finalImage = img.normalizedAndResized(
                maxWidth: 1200,
                maxHeight: 1200
            )
            
            if let data = finalImage.jpegData(compressionQuality: 0.85) {
                let name = UUID().uuidString + ".jpg"
                FileHelper.saveImageData(filename: name, data: data)
                recipe.imageFilename = name
            }
        }
        
        do {
            try context.save()
            dismiss()
        } catch {
            print("❌ Kunde inte spara:", error)
        }
        
    }
   

}// EditrecipeView är stängd här <-----
    
struct IngredientFormSection: View {
   
    @Binding var ingredientName: String
    @Binding var ingredientAmount: String
    @Binding var ingredientUnit: String
    
    let themeManager: ThemeManager
    let languageManager: LanguageManager
    let unitOptions: [String]
    let isValid: Bool
    //let hasSubmitted: Bool
    //let pulse: Bool
    @Binding var hasSubmitted: Bool
    @Binding var pulse: Bool
    let addIngredient: () -> Void
    let deleteIngredient: (IngredientEntity) -> Void
    let loadIngredientForEdit: (IngredientEntity) -> Void

    
    let recipe: Recipe
    let destructiveColor: Color
    
    private let fieldHeight: CGFloat = 52
    private var fieldStyle: some ViewModifier {
        FieldStyle(theme: themeManager)
    }
    
    private var editorStyle: some ViewModifier {
        EditorStyle(theme: themeManager)
    }
    
    var body: some View {
        // Group {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("ingredient", languageManager))
                .font(.headline)
            
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            TextField(L("ingredient", languageManager),text: $ingredientName)
                .modifier(fieldStyle)
                .tint(.white)
            TextField(L("amount", languageManager),text: $ingredientAmount
            )
            //.keyboardType(.decimalPad)
            .keyboardType(.numbersAndPunctuation)

            .modifier(fieldStyle)
            
            
            Menu {
                ForEach(unitOptions, id: \.self) { unit in
                    Button {
                        ingredientUnit = unit
                    } label: {
                        Text(L("unit.\(unit)", languageManager))
                        // .modifier(fieldStyle(theme: themeManager))
                    }
                }
            } label: {
                HStack {
                    Text(
                        
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
                    
                }
                .padding(.horizontal, 16)
                .frame(height: fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.buttonBackground)
                )
            }
            .buttonStyle(.plain)
            
            Button {
                hasSubmitted = true
                pulse = false
                addIngredient()
            } label: {
                Text(L("add_ingredient", languageManager))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
            }// blinkande text
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
            .buttonStyle(.plain)
            
            
            //färg på fältbakgrund
            ForEach(recipe.ingredientArray) { ingredient in
                HStack {
                   // Text("\(ingredient.amount.cleanString) \(ingredient.unit ?? "") \(ingredient.name ?? "")")
                    Text(
                        "\(ingredient.amount.cleanString) " +
                        L("unit.\(ingredient.unit ?? "")", languageManager) +
                        " \(ingredient.name ?? "")"
                    )

                        .foregroundColor(themeManager.currentTheme.primaryTextColor)

                    Spacer()

                    Button {
                        deleteIngredient(ingredient)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(destructiveColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.buttonBackground)
                )
                .onTapGesture {
                    loadIngredientForEdit(ingredient)   // ✅ ENDA platsen
                }
            }

     
                }
            }
        }



