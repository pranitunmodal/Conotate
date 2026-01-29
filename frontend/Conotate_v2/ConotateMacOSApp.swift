//
//  ConotateMacOSApp.swift
//  ConotateMacOS
//
//  Created from React TypeScript app
//

import SwiftUI

@main
struct ConotateMacOSApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
