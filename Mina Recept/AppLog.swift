//
//  AppLog.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-02-14.
//

import Foundation
import os

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "MinaRecept"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let share = Logger(subsystem: subsystem, category: "share")
    static let cloudkit = Logger(subsystem: subsystem, category: "cloudkit")
    static let storage = Logger(subsystem: subsystem, category: "storage")
}
