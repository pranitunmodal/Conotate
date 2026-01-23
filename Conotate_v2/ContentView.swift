//
//  ContentView.swift
//  ConotateMacOS
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isAuthenticated {
            // Main App Content
            GeometryReader { geometry in
                ZStack {
                    // Background
                    appState.themeColor
                        .ignoresSafeArea()
                    
                    // Dots pattern background
                    DotsPatternView()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Top Bar
                        TopBarView()
                            .environmentObject(appState)
                            .padding(.top, 40)
                        
                        // Main Content - takes remaining space
                        ZStack {
                            if appState.currentView == .home {
                                HomeView()
                                    .environmentObject(appState)
                                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            } else {
                                LibraryView()
                                    .environmentObject(appState)
                                    .transition(.move(edge: .bottom))
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height - 120) // Subtract top bar height
                        .animation(.easeInOut(duration: 0.4), value: appState.currentView)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    
                    // Modals
                    if appState.isNewSectionModalOpen {
                        NewSectionModalView()
                            .environmentObject(appState)
                    }
                    
                    if appState.expandedSectionId != nil {
                        SectionDetailModalView()
                            .environmentObject(appState)
                    }
                    
                    // Flying Note Animation
                    if let flyingNote = appState.flyingNote {
                        FlyingNoteView(note: flyingNote)
                            .environmentObject(appState)
                    }
                    
                    // API Key Entry Modal
                    if appState.needsAPIKey {
                        APIKeyEntryView()
                            .environmentObject(appState)
                    }
                }
            }
            .preferredColorScheme(appState.isDarkMode ? .dark : .light)
            .onAppear {
                appState.saveData()
            }
        } else {
            // Login View
            LoginView()
                .environmentObject(appState)
        }
    }
}

// Dots Pattern Background
struct DotsPatternView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let spacing: CGFloat = 10
                let dotSize: CGFloat = 0.6
                let rows = Int(size.height / spacing) + 1
                let cols = Int(size.width / spacing) + 1
                
                // Original color: rgba(196, 175, 160, 0.6) - signature taupe color
                let dotColor = Color(hex: "#C4AFA0").opacity(0.6)
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * spacing + spacing / 2
                        let y = CGFloat(row) * spacing + spacing / 2
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)),
                            with: .color(dotColor)
                        )
                    }
                }
            }
        }
    }
}
