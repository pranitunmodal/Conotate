//
//  TopBarView.swift
//  ConotateMacOS
//

import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var isMenuOpen = false
    
    var body: some View {
        HStack {
            Text("Conotate")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(.black.opacity(0.85))
                .tracking(-0.5)
            
            Spacer()
            
            HStack(spacing: 16) {
                Text("Hey, \(appState.userName)")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(appState.isDarkMode ? .gray.opacity(0.7) : .gray.opacity(0.6))
                
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isMenuOpen.toggle()
                        }
                    }) {
                        Text(appState.userAvatar)
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(appState.isDarkMode ? Color.gray.opacity(0.3) : Color(hex: "#F3F2EA"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(appState.isDarkMode ? Color.gray.opacity(0.4) : Color(hex: "#E8E6DC"), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    
                    if isMenuOpen {
                        MenuDropdownView(isOpen: $isMenuOpen)
                            .environmentObject(appState)
                            .offset(x: -100, y: 40)
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 999)
                .fill(appState.isDarkMode ? Color(hex: "#2A2A2A").opacity(0.95) : Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(appState.isDarkMode ? Color.white.opacity(0.1) : Color(hex: "#E8E6DC").opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 2)
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .onTapGesture {
            if isMenuOpen {
                withAnimation {
                    isMenuOpen = false
                }
            }
        }
    }
}

struct MenuDropdownView: View {
    @Binding var isOpen: Bool
    @EnvironmentObject var appState: AppState
    @State private var showImportDialog = false
    @State private var importText = ""
    
    // Computed properties to simplify type-checking
    private var accountTextColor: Color {
        appState.isDarkMode ? .gray.opacity(0.5) : .gray.opacity(0.4)
    }
    
    private var dividerColor: Color {
        appState.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    private var darkModeTitle: String {
        appState.isDarkMode ? "Light Mode" : "Dark Mode"
    }
    
    private var backgroundColor: Color {
        appState.isDarkMode ? Color(hex: "#333").opacity(0.9) : Color.white.opacity(0.9)
    }
    
    private var borderColor: Color {
        appState.isDarkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.5)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Account Header
            Text("ACCOUNT")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(accountTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
                .background(dividerColor)
            
            // Menu Items
            MenuButton(title: darkModeTitle) {
                appState.toggleDarkMode()
                isOpen = false
            }
            
            MenuButton(title: "Profile Settings") {
                // TODO: Implement profile settings
                isOpen = false
            }
            
            MenuButton(title: "Import Data") {
                showImportDialog = true
                isOpen = false
            }
            
            MenuButton(title: "Export Data") {
                appState.exportData()
                isOpen = false
            }
            
            Divider()
                .background(dividerColor)
            
            MenuButton(title: "Logout", action: {
                // TODO: Implement logout
                isOpen = false
            }, isDestructive: true)
        }
        .frame(width: 224)
        .background(menuBackground)
        .overlay(
            Group {
                if showImportDialog {
                    ImportDialogView(text: $importText, isPresented: $showImportDialog)
                        .environmentObject(appState)
                }
            }
        )
    }
    
    private var menuBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 40, x: 0, y: 10)
    }
}

struct MenuButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isDestructive ? .red : (appState.isDarkMode ? .gray.opacity(0.8) : .gray.opacity(0.7)))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Group {
                if !isDestructive {
                    Color.clear
                        .onHover { hovering in
                            // Hover effect handled by system
                        }
                }
            }
        )
    }
}

struct ImportDialogView: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("Import Data")
                    .font(.system(size: 18, weight: .semibold))
                
                TextEditor(text: $text)
                    .frame(width: 400, height: 200)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Import") {
                        appState.importData(json: text)
                        isPresented = false
                        text = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

extension AppState {
    func toggleDarkMode() {
        if isDarkMode {
            themeColor = Color(hex: "#FAF7F2")
        } else {
            themeColor = Color(hex: "#1A1A1A")
        }
        updateDarkMode()
        saveData()
    }
}
