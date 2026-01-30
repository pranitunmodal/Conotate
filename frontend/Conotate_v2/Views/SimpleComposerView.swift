//
//  SimpleComposerView.swift
//  ConotateMacOS
//

import SwiftUI
import AppKit

enum InputMode {
    case entry
    case search
    case settings
}

struct SimpleComposerView: View {
    @EnvironmentObject var appState: AppState
    @State private var mode: InputMode = .entry
    @State private var text = ""
    @State private var isClassifying = false
    @State private var showCommandMenu = false
    @State private var commandFilter = ""
    @State private var commandMenuIndex = 0
    @FocusState private var isFocused: Bool

    var commands: [Command] {
        var cmds: [Command] = [
            Command(id: "settings", label: "Settings", action: .settings, icon: "gearshape", kind: .action),
            Command(id: "search", label: "Search", action: .search, icon: "magnifyingglass", kind: .action),
            Command(id: "new", label: "Create New Section", action: .newSection, icon: "plus", kind: .action),
            Command(id: "import", label: "Import Note", action: .importNote, icon: "arrow.down", kind: .action),
            Command(id: "add-connector", label: "Add Connector", action: .addConnector, icon: "link", kind: .action)
        ]
        
        cmds.append(contentsOf: appState.sections.map { section in
            Command(id: section.id, label: section.name, action: .setSection(section.id), icon: nil, kind: .section)
        })
        
        let trimmedFilter = commandFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFilter.isEmpty {
            return cmds.filter { $0.label.localizedCaseInsensitiveContains(trimmedFilter) }
        }
        return cmds
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mode indicator
            HStack {
                Text(mode == .entry ? "Adding to →" : (mode == .search ? "Searching..." : "Settings"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.6) : .gray.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Input field + Command menu
            ZStack(alignment: .topLeading) {
                inputField
                if showCommandMenu && !commands.isEmpty {
                    CommandMenuView(
                        commands: commands,
                        selectedIndex: $commandMenuIndex,
                        onSelect: handleCommandSelect
                    )
                    .environmentObject(appState)
                    .offset(x: 0, y: 52)
                    .zIndex(10)
                }
            }
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
        
        if mode == .entry {
            if let switchCommand = modeSwitchCommand(from: newValue) {
                switch switchCommand.mode {
                case .search:
                    switchToSearchMode()
                case .settings:
                    mode = .settings
                case .entry:
                    break
                }
                text = switchCommand.remainder
                showCommandMenu = false
                commandFilter = ""
                commandMenuIndex = 0
                return
            }
            if let match = newValue.range(of: #"/[a-zA-Z0-9\s]*$"#, options: .regularExpression) {
                commandFilter = String(newValue[match]).dropFirst().trimmingCharacters(in: .whitespaces)
                commandMenuIndex = 0
                showCommandMenu = !commands.isEmpty
            } else {
                showCommandMenu = false
                commandFilter = ""
                commandMenuIndex = 0
            }
        } else {
            showCommandMenu = false
            commandFilter = ""
            commandMenuIndex = 0
        }
    }
    
    private func handleSubmit() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        if mode == .entry && trimmedText.lowercased().hasPrefix("/settings") {
            mode = .settings
            text = trimmedText.replacingOccurrences(of: #"/settings\s*"#, with: "", options: .regularExpression)
            showCommandMenu = false
            commandFilter = ""
            commandMenuIndex = 0
            return
        }

        if mode == .entry && trimmedText.lowercased().hasPrefix("/connector") {
            let name = trimmedText.replacingOccurrences(of: #"/connector\s*"#, with: "", options: .regularExpression)
            appState.addConnector(name: name)
            text = ""
            return
        }

        if mode == .entry && trimmedText.lowercased().hasPrefix("/search") {
            let query = trimmedText.replacingOccurrences(of: #"/search\s*"#, with: "", options: .regularExpression)
            switchToSearchMode()
            text = query
            appState.searchQuery = query
            return
        }

        if mode == .entry && trimmedText.lowercased().hasPrefix("/import") {
            appState.currentView = .settings
            appState.shouldShowImportDialog = true
            text = ""
            return
        }

        if mode == .entry && trimmedText.lowercased().hasPrefix("/new") {
            let content = trimmedText.replacingOccurrences(of: #"/new\s*"#, with: "", options: .regularExpression)
            appState.pendingContent = content
            appState.isNewSectionModalOpen = true
            text = ""
            return
        }
        
        if mode == .settings {
            if let setting = parseSettingsIntent(text) {
                appState.updateSettings(type: setting.type, value: setting.value)
            }
            text = ""
            switchToEntryMode()
            return
        }
        
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
        showCommandMenu = false
        commandFilter = ""
        commandMenuIndex = 0
    }
    
    private func switchToEntryMode() {
        mode = .entry
        appState.searchQuery = ""
        showCommandMenu = false
        commandFilter = ""
        commandMenuIndex = 0
    }

    private func moveCommandSelection(_ delta: Int) {
        guard !commands.isEmpty else { return }
        let nextIndex = commandMenuIndex + delta
        if nextIndex < 0 {
            commandMenuIndex = commands.count - 1
        } else if nextIndex >= commands.count {
            commandMenuIndex = 0
        } else {
            commandMenuIndex = nextIndex
        }
    }

    private func autocompleteCommand(_ command: Command) {
        guard let range = commandRange(in: text) else { return }
        let replacement = commandReplacement(for: command)
        text.replaceSubrange(range, with: replacement)
        showCommandMenu = false
        commandFilter = ""
        commandMenuIndex = 0
        switch command.action {
        case .settings:
            mode = .settings
            text = ""
        case .search:
            switchToSearchMode()
            text = ""
        default:
            break
        }
    }

    private func commandReplacement(for command: Command) -> String {
        switch command.action {
        case .settings:
            return "/settings "
        case .search:
            return "/search "
        case .newSection:
            return "/new "
        case .addConnector:
            return "/connector "
        case .importNote:
            return "/import "
        case .setSection(let id):
            if let section = appState.sections.first(where: { $0.id == id }) {
                return "@\(section.name) "
            }
            return "@"
        }
    }
    
    private func modeSwitchCommand(from input: String) -> (mode: InputMode, remainder: String)? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if let match = trimmed.range(of: #"^/search(?:\s+.*)?$"#, options: .regularExpression) {
            let remainder = String(trimmed[match]).replacingOccurrences(of: #"/search\s*"#, with: "", options: .regularExpression)
            return (.search, remainder)
        }
        if let match = trimmed.range(of: #"^/settings(?:\s+.*)?$"#, options: .regularExpression) {
            let remainder = String(trimmed[match]).replacingOccurrences(of: #"/settings\s*"#, with: "", options: .regularExpression)
            return (.settings, remainder)
        }
        return nil
    }

    private var inputField: some View {
        HStack(spacing: 8) {
            if mode == .search {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.5) : .gray.opacity(0.5))
                    .padding(.leading, 16)
            }
            
            TextField(
                mode == .settings ? "Type \"Dark Mode\", \"My name is...\", etc." : (mode == .entry ? "You type, we organize" : "Search..."),
                text: $text
            )
            .textFieldStyle(.plain)
            .font(.system(size: 16, weight: .regular))
            .focused($isFocused)
            .onChange(of: text) { oldValue, newValue in
                handleTextChange(newValue)
            }
            .onKeyPress(.return) {
                if let event = NSApp.currentEvent {
                    if showCommandMenu && !event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) {
                        if commands.indices.contains(commandMenuIndex) {
                            handleCommandSelect(commands[commandMenuIndex])
                            return .handled
                        }
                    }
                    if event.modifierFlags.contains(.command) {
                        handleSubmit()
                        return .handled
                    }
                }
                return .ignored
            }
            .onKeyPress(.downArrow) {
                if showCommandMenu {
                    moveCommandSelection(1)
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.upArrow) {
                if showCommandMenu {
                    moveCommandSelection(-1)
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.tab) {
                if showCommandMenu && commands.indices.contains(commandMenuIndex) {
                    autocompleteCommand(commands[commandMenuIndex])
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.escape) {
                if showCommandMenu {
                    showCommandMenu = false
                    commandFilter = ""
                    commandMenuIndex = 0
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.delete) {
                if text.isEmpty && mode != .entry {
                    switchToEntryMode()
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
            .padding(.vertical, 12)
            
            // Voice input (dummy – not hooked up)
            Button(action: {}) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14))
                    .foregroundColor(appState.isDarkMode ? .white.opacity(0.6) : .gray.opacity(0.6))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Voice input (coming soon)")
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appState.isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appState.isDarkMode ? Color.white.opacity(0.12) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func handleCommandSelect(_ command: Command) {
        if let range = commandRange(in: text) {
            text = String(text[..<range.lowerBound])
        }
        
        showCommandMenu = false
        commandFilter = ""
        commandMenuIndex = 0
        
        switch command.action {
        case .settings:
            mode = .settings
        case .search:
            switchToSearchMode()
        case .newSection:
            appState.pendingContent = text
            appState.isNewSectionModalOpen = true
        case .addConnector:
            appState.addConnector(name: "New Connector")
            appState.currentView = .settings
        case .importNote:
            appState.currentView = .settings
            appState.shouldShowImportDialog = true
            text = ""
        case .setSection(let id):
            if let section = appState.sections.first(where: { $0.id == id }) {
                text += "@\(section.name) "
            }
        }
    }

    private func commandRange(in value: String) -> Range<String.Index>? {
        if let match = value.range(of: #"/[a-zA-Z0-9\s]*$"#, options: .regularExpression) {
            return match
        }
        return nil
    }

    private func parseSettingsIntent(_ input: String) -> (type: String, value: String)? {
        let lower = input.lowercased()
        
        // Name change
        if let match = input.range(of: #"(?:change|set|update|my)?\s*name\s+(?:is|to)?\s*(.+)"#, options: [.regularExpression, .caseInsensitive]) {
            let name = String(input[match]).trimmingCharacters(in: .whitespaces)
            return ("name", name)
        }
        
        // Avatar/Emoji
        let emojiPattern = #"[\p{Emoji_Presentation}\p{Extended_Pictographic}]"#
        if let emojiRange = input.range(of: emojiPattern, options: .regularExpression) {
            let emoji = String(input[emojiRange])
            if lower.contains("avatar") || lower.contains("icon") || lower.contains("profile") || input.replacingOccurrences(of: emoji, with: "").trimmingCharacters(in: .whitespaces).count < 15 {
                return ("avatar", emoji)
            }
        }

        // Connectors
        if let connectorName = extractConnectorName(input) {
            return ("connector", connectorName)
        }
        
        // Theme
        if lower.contains("dark mode") {
            return ("theme", "dark mode")
        }
        if lower.contains("light mode") {
            return ("theme", "light mode")
        }
        
        // Hex color
        if let hexRange = input.range(of: #"#[0-9a-fA-F]{3,6}"#, options: .regularExpression) {
            return ("theme", String(input[hexRange]))
        }
        
        // Color name (last word)
        let words = input.trimmingCharacters(in: .whitespaces).split(separator: " ")
        if let lastWord = words.last, lastWord.allSatisfy({ $0.isLetter }) {
            return ("theme", String(lastWord))
        }
        
        return nil
    }

    private func extractConnectorName(_ input: String) -> String? {
        let pattern = #"(?:add|create|new|connect)\s+(?:a\s+)?connector\s+(.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(location: 0, length: input.utf16.count)
        guard let match = regex.firstMatch(in: input, options: [], range: range),
              match.numberOfRanges >= 2,
              let nameRange = Range(match.range(at: 1), in: input) else {
            return nil
        }
        let name = String(input[nameRange]).trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    struct CommandMenuView: View {
        let commands: [Command]
        @Binding var selectedIndex: Int
        let onSelect: (Command) -> Void
        @EnvironmentObject var appState: AppState
        
        private let maxVisibleCount = 8
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                menuHeader
                
                Group {
                    if commands.count > maxVisibleCount {
                        ScrollView {
                            commandList
                        }
                        .frame(maxHeight: 260)
                    } else {
                        commandList
                    }
                }
            }
            .frame(width: 256)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.12), radius: 40, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        
        private var menuHeader: some View {
            Text("COMMANDS")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
        }
        
        private var commandList: some View {
            VStack(alignment: .leading, spacing: 0) {
                let firstSectionIndex = commands.firstIndex(where: { $0.kind == .section })
                let hasActions = commands.contains(where: { $0.kind == .action })
                ForEach(Array(commands.enumerated()), id: \.element.id) { index, command in
                    if let firstSectionIndex = firstSectionIndex, hasActions, index == firstSectionIndex {
                        Divider()
                            .background(Color.gray.opacity(0.15))
                            .padding(.horizontal, 16)
                    }
                    CommandRow(
                        command: command,
                        isSelected: index == selectedIndex,
                        onSelect: { onSelect(command) }
                    )
                }
            }
        }
        
        struct CommandRow: View {
            let command: Command
            let isSelected: Bool
            let onSelect: () -> Void
            
            var body: some View {
                Button(action: onSelect) {
                    HStack(spacing: 12) {
                        leadingIcon
                        Text(command.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isSelected ? .gray.opacity(0.9) : .gray.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)
            }
            
            private var leadingIcon: some View {
                Group {
                    if command.kind == .section {
                        Text("SEC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#E8E6DC"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    } else if let icon = command.icon {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .frame(width: 28, alignment: .leading)
            }
        }
    }

    struct Command: Identifiable {
        let id: String
        let label: String
        let action: CommandAction
        let icon: String?
        let kind: CommandKind
    }
    
    enum CommandKind {
        case action
        case section
    }

    enum CommandAction {
        case settings
        case search
        case newSection
        case addConnector
        case importNote
        case setSection(String)
    }
}
