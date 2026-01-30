//
//  ContentView.swift
//  ConotateMacOS
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAccountMenu = false
    
    var body: some View {
        if appState.isAuthenticated {
            // Main App Content
            VStack(spacing: 0) {
                // Simple top bar
                HStack {
                    Text("Conotate")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundColor(.primary)
                        .padding(.leading, 16)
                        .padding(.top, 16)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Text("Hey, \(appState.displayName)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(appState.isDarkMode ? .white.opacity(0.6) : .gray.opacity(0.6))
                        
                        Button(action: {
                            showAccountMenu.toggle()
                        }) {
                            Text(appState.userAvatar)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(appState.isDarkMode ? Color.white.opacity(0.15) : Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showAccountMenu, arrowEdge: .top) {
                            MenuDropdownView(isOpen: $showAccountMenu)
                                .environmentObject(appState)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                
                // Main Content
                Group {
                    switch appState.currentView {
                    case .home:
                        HomeView()
                    case .library:
                        LibraryView()
                    case .profile:
                        ProfileView()
                    case .settings:
                        SettingsView()
                    }
                }
                .environmentObject(appState)
            }
            .background(appState.themeColor)
            .preferredColorScheme(appState.isDarkMode ? .dark : .light)
            .onAppear {
                appState.saveData()
            }
            .overlay {
                if appState.editingNoteId != nil {
                    EditNoteModalView()
                        .environmentObject(appState)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: appState.editingNoteId != nil)
        } else {
            // Login View
            LoginView()
                .environmentObject(appState)
        }
    }
}
