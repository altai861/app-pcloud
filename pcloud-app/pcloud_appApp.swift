//
//  pcloud_appApp.swift
//  pcloud-app
//
//  Created by Altai Gantumur on 2026.03.04.
//

import SwiftUI

@main
struct pcloud_appApp: App {
    @StateObject private var settingsStore: AppSettingsStore
    @StateObject private var sessionStore: SessionStore

    init() {
        let settingsStore = AppSettingsStore()
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _sessionStore = StateObject(wrappedValue: SessionStore(settingsStore: settingsStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(sessionStore)
                .environment(\.locale, settingsStore.locale)
                .preferredColorScheme(settingsStore.themePreference.colorScheme)
        }
    }
}
