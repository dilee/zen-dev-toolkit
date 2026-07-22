//
//  AppState.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2026-07-22.
//

import SwiftUI

// Shared, session-only state for the menu bar panel.
final class AppState: ObservableObject {
    static let shared = AppState()

    // Ordered tool tags - single source of truth for the header order and ⌘1–⌘7 shortcuts
    static let toolTags = ["JSON", "Base64", "URL", "Hash", "UUID", "Time", "JWT"]

    // Keeps the panel open while clicking other apps. Deliberately not persisted.
    @Published var isPinned = false

    private init() {}
}
