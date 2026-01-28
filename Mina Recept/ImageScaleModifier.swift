//
//  ImageScaleModifier.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-04.
//


import SwiftUI

struct ImageScaleModifier: ViewModifier {
    let useFill: Bool

    func body(content: Content) -> some View {
        if useFill {
            content.scaledToFill()
        } else {
            content
                .scaledToFit()
                .padding(12)
        }
    }
}
