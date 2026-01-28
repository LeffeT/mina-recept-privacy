//
//  ShareSheet.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-30.
//


//
//  ShareSheet.swift
//  Mina Recept
//
//  Skapar lokalt PendingRecipePayload och delar ENDAST länk
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    @EnvironmentObject var languageManager: LanguageManager


    let title: String
    let instructions: String
    let image: UIImage?
    let ingredients: [PendingIngredient]
  


    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("INGREDIENTS COUNT =", ingredients.count)
        print("🟡 ShareSheet opened")
        print("INGREDIENTS COUNT =", ingredients.count)


        let id = UUID().uuidString
        var imageFilename: String? = nil

        // 📸 Bild är VALFRI
        if let image = image,
           let data = image.jpegData(compressionQuality: 0.85) {

            let filename = "\(id).jpg"
            FileHelper.saveImageData(
                filename: filename,
                data: data
            )
            imageFilename = filename
        }

        let payload = PendingRecipePayload(
            id: id,
            title: title,
            instructions: instructions,
            imageFilename: imageFilename,
            ingredients: ingredients
        )
        print("🟡 About to save payload:", payload.id)
        PendingRecipePayloadStore.save(payload)
        print("📦 Pending payload saved:", id)

      
        let linkString = "minarecept://import?id=\(payload.id)"

        let header = String(
            format: L("share_recipe_title", languageManager),
            title
        )

        let openText = L("share_open_in_app", languageManager)

        let text = """
        \(header)

        \(openText)
        \(linkString)
        """

        return UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
