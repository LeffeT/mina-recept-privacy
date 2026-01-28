//
//  DeepLinkManager.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2025-12-31.
//


//
//  DeepLinkManager.swift
//  Mina Recept
//

import Foundation
import Combine
import os

final class DeepLinkManager: ObservableObject {

    @Published var pendingRecipeID: String?

    // 📊 Logger för deep links
    private let logger = Logger(
        subsystem: "com.se.leiftarvainen.minarecept",
        category: "deeplink"
    )

    func handle(_ url: URL) {
        logger.info("Deep link received: \(url.absoluteString)")

        guard url.scheme == "minarecept" else {
            logger.warning("Deep link ignored – wrong scheme")
            return
        }

        guard url.host == "import" else {
            logger.warning("Deep link ignored – unknown host")
            return
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let id = components?
            .queryItems?
            .first(where: { $0.name == "id" })?
            .value

        guard let id else {
            logger.error("Deep link missing recipeID")
            return
        }

        DispatchQueue.main.async {
            self.pendingRecipeID = id
            self.logger.info("pendingRecipeID set: \(id)")
        }
    }

    func clear() {
        guard pendingRecipeID != nil else { return }

        logger.info("Clearing pendingRecipeID")
        pendingRecipeID = nil
    }
}
