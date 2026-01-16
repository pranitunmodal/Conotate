//
//  HomeView.swift
//  ConotateMacOS
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Composer Area - takes remaining space
            ScrollView {
                VStack(spacing: 0) {
                    ComposerView(
                        variant: .hero,
                        showClassificationPreview: true
                    )
                    .environmentObject(appState)
                    .padding(.top, 16)
                    .padding(.bottom, 140) // Space for bottom panel
                }
                .frame(maxWidth: .infinity)
            }
            
            // Section Panel at Bottom
            SectionPanelView()
                .environmentObject(appState)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
