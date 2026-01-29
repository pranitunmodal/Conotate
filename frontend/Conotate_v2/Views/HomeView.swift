//
//  HomeView.swift
//  ConotateMacOS
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Simple Composer at top
            SimpleComposerView()
                .environmentObject(appState)
            
            // Collapsible sections list
            CollapsibleSectionListView()
                .environmentObject(appState)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
