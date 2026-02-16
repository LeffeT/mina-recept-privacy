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
import CloudKit
import os


struct ShareSheet: UIViewControllerRepresentable {
    @EnvironmentObject var languageManager: LanguageManager

    let title: String
    let instructions: String
    let image: UIImage?
    let ingredients: [PendingIngredient]
    let baseServings: Int

    func makeUIViewController(context: Context) -> UIActivityViewController {
    #if DEBUG
        AppLog.share.debug("Ingredients count: \(self.ingredients.count, privacy: .public)")
        AppLog.share.debug("ShareSheet opened")
    #endif

        // 🔑 Ett ID per share-session
        let id = UUID().uuidString

        // 🖼️ Bild är valfri
        var imageFilename: String? = nil

        if let image = image,
           let data = image.jpegData(compressionQuality: 0.85) {

            let filename = "\(id).jpg"
            FileHelper.saveImageData(
                filename: filename,
                data: data
            )
            imageFilename = filename
        }

        // 🔗 Deep link (använder ID direkt)
        let linkURL = URL(string: "minarecept://import?id=\(id)")!


        let header = String(
            format: L("share_recipe_title", languageManager),
            title
        )

        let openText = L("share_open_in_app", languageManager)

        let text = """
        \(header)

        \(openText)
        \(linkURL)
        """

        var items: [Any] = []

        if let image = image {
            items.append(image)
        }

        items.append(text)
        // Link already included in text; avoid duplicating it as a separate item.

        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )


        // ✅ ENDA platsen där payload sparas
        controller.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else {
            #if DEBUG
                AppLog.share.debug("Share cancelled – no payload saved")
            #endif

                return
            }

        let expiresAt = Date().addingTimeInterval(CloudKitService.shareTTL)
        let payload = PendingRecipePayload(
            id: id,
            title: title,
            instructions: instructions,
            imageFilename: imageFilename,
            ingredients: ingredients,
            expiresAt: expiresAt,
            baseServings: max(1, baseServings)
        )
          #if DEBUG
            AppLog.share.info("Share confirmed – saving payload: \(payload.id, privacy: .public)")
           #endif
            
            //PendingRecipePayloadStore.save(payload)
            CloudKitService.shared.savePublicRecipe(payload)

         

        }

        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
        // Nothing to update
    }
}
