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
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Button(action: {
                            appState.logout()
                        }) {
                            Text("Logout")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Text(appState.userAvatar)
                            .font(.system(size: 16))
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                
                // Main Content
                HomeView()
                    .environmentObject(appState)
            }
            .background(appState.themeColor)
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
