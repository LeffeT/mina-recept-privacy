//
//  CookingModeManager.swift
//  Mina Recept
//
//  Created by OpenAI Codex on 2026-03-23.
//

import Combine
import Foundation
import UIKit

@MainActor
final class CookingModeManager: ObservableObject {
    private let key = "cooking_mode_enabled"

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: key)
            updateIdleTimer()
        }
    }

    private var isAppActive = false

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: key)
    }

    func setAppActive(_ isActive: Bool) {
        isAppActive = isActive
        updateIdleTimer()
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = isEnabled && isAppActive
    }
}
