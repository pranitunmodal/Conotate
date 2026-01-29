//
//  SimpleComposerView.swift
//  ConotateMacOS
//

import SwiftUI
import AppKit

enum InputMode {
    case entry
    case search
}

struct SimpleComposerView: View {
    @EnvironmentObject var appState: AppState
    @State private var mode: InputMode = .entry
    @State private var text = ""
    @State private var isClassifying = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mode indicator
            HStack {
                Text(mode == .entry ? "Adding to →" : "Searching...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Input field
            HStack {
                if mode == .search {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.leading, 16)
                }
                
                TextField(
                    mode == .entry ? "You type, we organize" : "Search...",
                    text: $text
                )
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .regular))
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    handleTextChange(newValue)
                }
                .onKeyPress(.return) {
                    if let event = NSApp.currentEvent, event.modifierFlags.contains(.command) {
                        handleSubmit()
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(KeyEquivalent(Character("s"))) {
                    if let event = NSApp.currentEvent, event.modifierFlags.contains(.command) {
                        switchToSearchMode()
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(KeyEquivalent(Character("e"))) {
                    if let event = NSApp.currentEvent, event.modifierFlags.contains(.command) {
                        switchToEntryMode()
                        return .handled
                    }
                    return .ignored
                }
                .padding(.horizontal, mode == .search ? 8 : 16)
                .padding(.vertical, 12)
            }
            .background(Color.white.opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(appState.themeColor)
        .onAppear {
            isFocused = true
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        if mode == .search {
            appState.searchQuery = newValue
        }
    }
    
    private func handleSubmit() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        if mode == .entry {
            submitEntry()
        } else {
            // In search mode, Cmd+Return could trigger a search action if needed
            // For now, just keep it in search mode
        }
    }
    
    private func submitEntry() {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }
        
        // Check for @section entry pattern
        if let atIndex = trimmedText.firstIndex(of: "@") {
            let afterAt = String(trimmedText[trimmedText.index(after: atIndex)...])
            if let spaceIndex = afterAt.firstIndex(of: " ") {
                let sectionName = String(afterAt[..<spaceIndex]).trimmingCharacters(in: .whitespaces)
                let entryText = String(afterAt[afterAt.index(after: spaceIndex)...]).trimmingCharacters(in: .whitespaces)
                
                if !sectionName.isEmpty && !entryText.isEmpty {
                    // Create new section and add entry
                    appState.createNewSection(title: sectionName, tags: [], content: entryText)
                    text = ""
                    return
                }
            }
        }
        
        // Check for command patterns (/task, /idea, /note)
        var commandSectionId: String? = nil
        var entryText = trimmedText
        
        if trimmedText.hasPrefix("/task") {
            commandSectionId = "tasks"
            entryText = String(trimmedText.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        } else if trimmedText.hasPrefix("/idea") {
            commandSectionId = "ideas"
            entryText = String(trimmedText.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        } else if trimmedText.hasPrefix("/note") {
            commandSectionId = "notes"
            entryText = String(trimmedText.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        }
        
        guard !entryText.isEmpty else { return }
        
        // Classify and add note
        isClassifying = true
        Task {
            do {
                let sectionId: String
                if let commandId = commandSectionId {
                    sectionId = commandId
                } else {
                    // Use AI classification
                    let result = try await GroqService.shared.classifyNote(entryText, availableSections: appState.sections)
                    sectionId = result.sectionId
                }
                
                await MainActor.run {
                    appState.addNote(text: entryText, sectionId: sectionId)
                    // Auto-expand the section that received the note
                    appState.expandedSectionId = sectionId
                    text = ""
                    isClassifying = false
                }
            } catch {
                // Fallback to keyword-based classification
                await MainActor.run {
                    let sectionId = commandSectionId ?? Utils.classifyNote(entryText)
                    appState.addNote(text: entryText, sectionId: sectionId)
                    appState.expandedSectionId = sectionId
                    text = ""
                    isClassifying = false
                }
            }
        }
    }
    
    private func switchToSearchMode() {
        mode = .search
        appState.searchQuery = text
    }
    
    private func switchToEntryMode() {
        mode = .entry
        appState.searchQuery = ""
    }
}
