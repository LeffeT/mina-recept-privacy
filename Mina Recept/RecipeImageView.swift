//
//  RecipeImageView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-14.
//


//
//  RecipeImageView.swift
//  Mina Recept
//
//  Skapad för att matcha EditRecipeView exakt
//

import SwiftUI

struct RecipeImageView: View {

    let image: UIImage?
    let noImageText: String

    // Samma värden som EditRecipeView
    private let formMaxWidth: CGFloat = 700

    private var imageHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 520 : 340
    }

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let imageWidth = min(
                availableWidth - 2,
                UIDevice.current.userInterfaceIdiom == .pad ? 700 : 520
            )

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: imageWidth, height: imageHeight)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                        Text(noImageText)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: imageHeight)
        .padding(.horizontal, 2)
    }
}
