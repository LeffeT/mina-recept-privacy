//
//  UIImage+Resize.swift
//  Matlagning
//
//  Created by Leif Tarvainen on 2025-12-13.
//

import UIKit

extension UIImage {

    /// Fixar EXIF-orientation och skalar ned bilden
    /// – behåller ALLTID proportioner
    /// – zoomar aldrig in
    /// – förstorar aldrig små bilder
    func normalizedAndResized(
        maxWidth: CGFloat,
        maxHeight: CGFloat
    ) -> UIImage {

        // 1️⃣ Normalisera orientation (kamera-buggen)
        let normalizedImage: UIImage
        if imageOrientation == .up {
            normalizedImage = self
        } else {
            let renderer = UIGraphicsImageRenderer(size: size)
            normalizedImage = renderer.image { _ in
                self.draw(in: CGRect(origin: .zero, size: size))
            }
        }

        // 2️⃣ Räkna skalfaktor (behåll proportioner)
        let widthRatio  = maxWidth / normalizedImage.size.width
        let heightRatio = maxHeight / normalizedImage.size.height

        let scale = min(widthRatio, heightRatio, 1.0) // aldrig förstora

        let newSize = CGSize(
            width: normalizedImage.size.width * scale,
            height: normalizedImage.size.height * scale
        )

        // 3️⃣ Skala ned
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            normalizedImage.draw(
                in: CGRect(origin: .zero, size: newSize)
            )
        }
    }
}


