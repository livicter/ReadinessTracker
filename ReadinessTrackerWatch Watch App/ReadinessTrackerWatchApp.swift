//
//  ReadinessTrackerWatchApp.swift
//  ReadinessTrackerWatch Watch App
//
//  Created by 🦭 Victor on 30/5/2026.
//

import SwiftUI

@main
struct ReadinessTracker_Watch_AppApp: App {
    @StateObject private var session = WatchSessionManager.shared

    init() {
        WatchSessionManager.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
