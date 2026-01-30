//
//  SettingsView.swift
//  ConotateMacOS
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImportDialog = false
    @State private var importText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    appearanceSection
                    accountSection
                    dataSection
                    connectorsSection
                }
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(
            Group {
                if showImportDialog {
                    ImportDialogView(text: $importText, isPresented: $showImportDialog)
                        .environmentObject(appState)
                }
            }
        )
    }
    
    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundColor(appState.isDarkMode ? .white.opacity(0.9) : .black.opacity(0.8))
            
            Spacer()
            
            TypewriterButton(variant: .secondary) {
                appState.currentView = .home
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10))
                    Text("Back")
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }
    }
    
    private var connectorsSection: some View {
        settingsCard(title: "CONNECTORS") {
            HStack {
                Text("Manage connectors for external services.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.6) : .gray.opacity(0.6))
                Spacer()
                TypewriterButton(variant: .secondary) {
                    appState.addConnector(name: "New Connector")
                } label: {
                    HStack(spacing: 4) {
                        Text("Add Connector")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                    }
                }
            }
            
            if appState.connectors.isEmpty {
                Text("No connectors yet.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.6) : .gray.opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(appState.connectors) { connector in
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .font(.system(size: 12))
                                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.5) : .gray.opacity(0.6))
                                Text(connector.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.85) : .gray.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Button {
                                appState.removeConnector(id: connector.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.5) : .gray.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(appState.isDarkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(appState.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        settingsCard(title: "APPEARANCE") {
            HStack {
                Text("Dark Mode")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.85) : .gray.opacity(0.8))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.isDarkMode },
                    set: { _ in appState.toggleDarkMode() }
                ))
                .labelsHidden()
            }
        }
    }
    
    private var accountSection: some View {
        settingsCard(title: "ACCOUNT") {
            Button {
                appState.currentView = .profile
            } label: {
                HStack {
                    Text("Profile Settings")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(appState.isDarkMode ? .white.opacity(0.85) : .gray.opacity(0.8))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(appState.isDarkMode ? .white.opacity(0.5) : .gray.opacity(0.4))
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var dataSection: some View {
        settingsCard(title: "DATA") {
            VStack(spacing: 8) {
                Button {
                    showImportDialog = true
                } label: {
                    settingsRowTitle("Import Data")
                }
                .buttonStyle(.plain)
                
                Button {
                    appState.exportData()
                } label: {
                    settingsRowTitle("Export Data")
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(appState.isDarkMode ? .white.opacity(0.5) : .gray.opacity(0.5))
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appState.isDarkMode ? Color.white.opacity(0.08) : Color(hex: "#F3F2EA"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appState.isDarkMode ? Color.white.opacity(0.12) : Color(hex: "#E8E6DC"), lineWidth: 1)
                )
        )
    }
    
    private func settingsRowTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(appState.isDarkMode ? .white.opacity(0.85) : .gray.opacity(0.8))
            Spacer()
        }
    }
}
