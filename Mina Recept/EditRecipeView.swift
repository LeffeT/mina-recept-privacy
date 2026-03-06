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
import os

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
    @State private var didPickNewImage = false
    @State private var originalImageFilename: String?
    @State private var showCamera = false
    @State private var ingredient = ""
    @State private var ingredientName: String = ""
    @State private var ingredientAmount: String = ""
    @State private var amount = ""
    @State private var unit = ""
    @State private var newUnit = ""
    @State private var showAddIngredient = false
    @State private var pulse = false
    @State private var hasSubmitted = false
    @State private var ingredientUnit: String = ""
    @State private var ingredientGroupIndex: Int = 0
    @State private var groupTitle1: String = ""
    @State private var groupTitle2: String = ""
    @State private var groupTitle3: String = ""
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
        "\(L("serves", languageManager)) \(recipe.baseServings)"
    }
    private var fieldStyle: some ViewModifier {
        FieldStyle(theme: themeManager)
    }
    private func loadIngredientForEdit(_ ingredient: IngredientEntity) {
      ingredientName = ingredient.name ?? ""
      ingredientAmount = ingredient.amountText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
      ? (ingredient.amountText ?? "")
      : ingredient.amount.cleanString
        ingredientUnit = unitKey(fromLocalized: ingredient.unit ?? "")
        ingredientGroupIndex = ingredient.safeGroupIndex
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
    
    private var currentGroupTitle: Binding<String> {
        switch ingredientGroupIndex {
        case 1:
            return $groupTitle2
        case 2:
            return $groupTitle3
        default:
            return $groupTitle1
        }
    }
    
    private func normalizedGroupTitle(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }


    
    // MARK: - UI helpers  ← ✅ HÄR
    @ViewBuilder
    func themedTextField(
        _ key: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(L(key, languageManager))
                .foregroundColor(themeManager.currentTheme.placeholderTextColor)
        )
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
                        .tint(themeManager.currentTheme.primaryTextColor)
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
                        TextField(
                            "",
                            text: $title,
                            prompt: Text(L("title_placeholder", languageManager))
                                .foregroundColor(themeManager.currentTheme.placeholderTextColor)
                        )
                            .modifier(fieldStyle)
                            .tint(themeManager.currentTheme.primaryTextColor)
                        
                        // Recept
                        IngredientFormSection(
                            ingredientName: $ingredientName,
                            ingredientAmount: $ingredientAmount,
                            ingredientUnit: $ingredientUnit,
                            groupIndex: $ingredientGroupIndex,
                            groupTitle1: $groupTitle1,
                            groupTitle2: $groupTitle2,
                            groupTitle3: $groupTitle3,
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
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        label(L("instructions", languageManager))
                        
                        TextEditor(text: $instructions)
                            .tint(themeManager.currentTheme.primaryTextColor)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            .padding(12)
                            .frame(minHeight: 220)
                            .background(editorBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .scrollContentBackground(.hidden)
                            .scrollDisabled(false)   // ✅ scrollar när man skriver
                    }
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
            groupTitle1 = recipe.group1Title ?? L("ingredients", languageManager)
            groupTitle2 = recipe.group2Title ?? ""
            groupTitle3 = recipe.group3Title ?? ""
            
            if let filename = recipe.imageFilename {
                pickedImage = FileHelper.loadImage(filename: filename)
            }
            originalImageFilename = recipe.imageFilename
            didPickNewImage = false
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(source: .camera) { image in
                pickedImage = image
                didPickNewImage = true
                showCamera = false
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = image
                    didPickNewImage = true
                }
            }
        }
    }// Här Stängs body <----
    
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
        ing.amountText = ingredientAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        ing.unit = ingredientUnit
        ing.scalable = true
        ing.groupIndex = Int16(ingredientGroupIndex)
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
        recipe.group1Title = normalizedGroupTitle(groupTitle1)
        recipe.group2Title = normalizedGroupTitle(groupTitle2)
        recipe.group3Title = normalizedGroupTitle(groupTitle3)
        
        if didPickNewImage, let img = pickedImage {
            let finalImage = img.normalizedAndResized(
                maxWidth: 1200,
                maxHeight: 1200
            )
            
            if let data = finalImage.jpegData(compressionQuality: 0.85) {
                let name = UUID().uuidString + ".jpg"
                if FileHelper.saveImageData(filename: name, data: data) {
                    let oldFilename = recipe.imageFilename
                    recipe.imageFilename = name
                    originalImageFilename = oldFilename
                } else {
                    didPickNewImage = false
                }
            }
        }
        
        do {
            try context.save()
            if let oldFilename = originalImageFilename,
               oldFilename != recipe.imageFilename {
                FileHelper.deleteImage(filename: oldFilename)
            }
            dismiss()
        } catch {
            if let filename = recipe.imageFilename,
               filename != originalImageFilename,
               didPickNewImage {
                FileHelper.deleteImage(filename: filename)
                recipe.imageFilename = originalImageFilename
            }
            AppLog.storage.error("Kunde inte spara: \(error.localizedDescription, privacy: .public)")
        }
        
    }
   

}// EditrecipeView är stängd här <-----
    
struct IngredientFormSection: View {
   
    @Binding var ingredientName: String
    @Binding var ingredientAmount: String
    @Binding var ingredientUnit: String
    @Binding var groupIndex: Int
    @Binding var groupTitle1: String
    @Binding var groupTitle2: String
    @Binding var groupTitle3: String
    
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
    
    private var currentGroupTitle: Binding<String> {
        switch groupIndex {
        case 1:
            return $groupTitle2
        case 2:
            return $groupTitle3
        default:
            return $groupTitle1
        }
    }
    
    private var filteredIngredients: [IngredientEntity] {
        recipe.ingredientArray.filter { $0.safeGroupIndex == groupIndex }
    }
    
    var body: some View {
        // Group {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(
                    "",
                    text: currentGroupTitle,
                    prompt: Text(L("ingredients", languageManager))
                        .foregroundColor(themeManager.currentTheme.placeholderTextColor)
                )
                .textFieldStyle(.plain)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)

                Spacer()

                Group {
                    if themeManager.currentTheme == .white {
                        Picker("", selection: $groupIndex) {
                            Text("1").tag(0)
                            Text("2").tag(1)
                            Text("3").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 140)
                        .environment(\.colorScheme, .light)
                    } else {
                        Picker("", selection: $groupIndex) {
                            Text("1").tag(0)
                            Text("2").tag(1)
                            Text("3").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 140)
                    }
                }
            }
            
            TextField(
                "",
                text: $ingredientName,
                prompt: Text(L("ingredient", languageManager))
                    .foregroundColor(themeManager.currentTheme.placeholderTextColor)
            )
                .modifier(fieldStyle)
                .tint(themeManager.currentTheme.primaryTextColor)
            TextField(
                "",
                text: $ingredientAmount,
                prompt: Text(L("amount", languageManager))
                    .foregroundColor(themeManager.currentTheme.placeholderTextColor)
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
            
            Button {
                hasSubmitted = true
                pulse = false
                addIngredient()
            } label: {
                Text(L("add_ingredient", languageManager))
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
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
            ForEach(filteredIngredients) { ingredient in
                HStack {
                    let rawAmount = ingredient.amountText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let amountString = rawAmount.isEmpty ? ingredient.amount.cleanString : rawAmount
                    Text(
                        "\(amountString) " +
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
