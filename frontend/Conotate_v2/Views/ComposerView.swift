//
//  ComposerView.swift
//  ConotateMacOS
//

import SwiftUI
import AppKit

struct ComposerView: View {
    @EnvironmentObject var appState: AppState
    let variant: ComposerVariant
    var autoFocus: Bool = false
    var initialText: String = ""
    var showClassificationPreview: Bool = true
    var onTextChange: ((String) -> Void)?
    
    @State private var text = ""
    @State private var selectedSectionId: String? = nil
    @State private var isSectionMenuOpen = false
    @State private var isTyping = false
    @State private var isSettingsMode = false
    @State private var isAnalyzing = false
    @State private var placeholder = ""
    @State private var placeholderIndex = 0
    @State private var isDeleting = false
    @State private var showCommandMenu = false
    @State private var commandFilter = ""
    @State private var commandMenuIndex = 0
    @State private var aiClassificationTask: Task<Void, Never>? = nil
    @State private var classifiedSectionId: String? = nil
    @State private var classificationConfidence: Double = 1.0
    
    @FocusState private var isFocused: Bool
    
    enum ComposerVariant {
        case hero
        case bar
    }
    
    var activeSectionId: String {
        // Priority: user override > AI classification > keyword fallback
        if let override = selectedSectionId {
            return override
        }
        if let aiClassified = classifiedSectionId {
            return aiClassified
        }
        return Utils.classifyNote(text)
    }
    
    var activeSection: Section {
        appState.sections.first { $0.id == activeSectionId } ?? appState.sections.first ?? Section(name: "Notes")
    }
    
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
        Group {
            if variant == .hero {
                heroVariant
            } else {
                barVariant
            }
        }
    }

    var heroVariant: some View {
        VStack(spacing: 0) {
            // System Info Row
            HStack {
                if !isSettingsMode {
                    HStack(spacing: 8) {
                        Text("Adding to →")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(Color(hex: "#C4AFA0"))
                        
                        if !text.isEmpty && showClassificationPreview {
                            if isAnalyzing {
                                AnalyzingPill()
                            } else {
                                SectionSelectorView(
                                    selectedSectionId: $selectedSectionId,
                                    classifiedSectionId: $classifiedSectionId,
                                    text: $text
                                )
                                    .environmentObject(appState)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if !text.isEmpty && !isSettingsMode {
                    TypewriterButton(variant: .ghost) {
                        appState.pendingContent = text
                        appState.isNewSectionModalOpen = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Add To New Section")
                                .font(.system(size: 10, weight: .bold, design: .default))
                                .tracking(1)
                            Image(systemName: "plus")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .frame(height: 32)
            .padding(.horizontal, 32)
            
            Divider()
                .background(Color(hex: "#C4AFA0").opacity(0.4))
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
            
            // Main Textarea Area
            HStack(alignment: .top, spacing: 8) {
                if isSettingsMode {
                    SettingsPill()
                        .padding(.top, 6)
                }
                
                ZStack(alignment: .topLeading) {
                    if text.isEmpty && !isSettingsMode {
                        Text(placeholder.isEmpty ? Constants.placeholders[0] : placeholder)
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "#D4C4B8"))
                            .padding(.leading, 5)
                            .padding(.top, 8)
                    }
                    
                    TextEditor(text: $text)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 200)
                        .padding(.leading, -4)
                        .padding(.top, -4)
                        .scrollIndicators(.hidden)
                        .focused($isFocused)
                        .onChange(of: text) { oldValue, newValue in
                            handleTextChange(newValue)
                        }
                        .onKeyPress(.return, action: {
                            // Check modifiers using NSEvent
                            if let event = NSApp.currentEvent {
                                if showCommandMenu && !event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) {
                                    if commands.indices.contains(commandMenuIndex) {
                                        handleCommandSelect(commands[commandMenuIndex])
                                        return .handled
                                    }
                                }
                                if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
                                    appState.pendingSearchQuery = text
                                    appState.currentView = .library
                                    return .handled
                                } else if event.modifierFlags.contains(.command) {
                                    handleSubmit()
                                    return .handled
                                }
                            }
                            return .ignored
                        })
                        .onKeyPress(.downArrow, action: {
                            if showCommandMenu {
                                moveCommandSelection(1)
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.upArrow, action: {
                            if showCommandMenu {
                                moveCommandSelection(-1)
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.tab, action: {
                            if showCommandMenu && commands.indices.contains(commandMenuIndex) {
                                autocompleteCommand(commands[commandMenuIndex])
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.escape, action: {
                            if showCommandMenu {
                                showCommandMenu = false
                                commandFilter = ""
                                commandMenuIndex = 0
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.delete, action: {
                            if isSettingsMode && text.isEmpty {
                                isSettingsMode = false
                                isTyping = false
                                showCommandMenu = false
                                commandFilter = ""
                                commandMenuIndex = 0
                                return .handled
                            }
                            return .ignored
                        })
                }
                .overlay(alignment: .topLeading) {
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
                .id("composer-textarea")
            }
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            
            
            if isSettingsMode {
                TypewriterButton(variant: .dark) {
                    handleSubmit()
                } label: {
                    Text("Apply Settings")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.top, 32)
            }
        }
        .frame(maxWidth: 800)
        .onAppear {
            if autoFocus {
                isFocused = true
            }
            text = initialText
            isTyping = !initialText.isEmpty
            startTypewriter()
        }
    }
    
    var barVariant: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                // Left: Section Selector
                if !isSettingsMode {
                    HStack(spacing: 8) {
                        Text("Adding to →")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#C4AFA0"))
                        
                        if !text.isEmpty && showClassificationPreview {
                            if isAnalyzing {
                                AnalyzingPill()
                            } else {
                                SectionSelectorView(
                                    selectedSectionId: $selectedSectionId,
                                    classifiedSectionId: $classifiedSectionId,
                                    text: $text
                                )
                                    .environmentObject(appState)
                            }
                        }
                    }
                    .frame(minWidth: 120)
                }
                
                // Center: Input
                HStack(alignment: .center, spacing: 8) {
                    if isSettingsMode {
                        SettingsPill()
                    }
                    
                    TextField("", text: $text, prompt: Text(isTyping || isSettingsMode ? "" : (placeholder.isEmpty ? Constants.placeholders[0] : placeholder)).foregroundColor(Color(hex: "#DDCDC1")))
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onChange(of: text) { oldValue, newValue in
                            handleTextChange(newValue)
                        }
                        .onKeyPress(.return, action: {
                            // Check modifiers using NSEvent
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
                        })
                        .onKeyPress(.downArrow, action: {
                            if showCommandMenu {
                                moveCommandSelection(1)
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.upArrow, action: {
                            if showCommandMenu {
                                moveCommandSelection(-1)
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.tab, action: {
                            if showCommandMenu && commands.indices.contains(commandMenuIndex) {
                                autocompleteCommand(commands[commandMenuIndex])
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.escape, action: {
                            if showCommandMenu {
                                showCommandMenu = false
                                commandFilter = ""
                                commandMenuIndex = 0
                                return .handled
                            }
                            return .ignored
                        })
                        .onKeyPress(.delete, action: {
                            if isSettingsMode && text.isEmpty {
                                isSettingsMode = false
                                isTyping = false
                                showCommandMenu = false
                                commandFilter = ""
                                commandMenuIndex = 0
                                return .handled
                            }
                            return .ignored
                        })
                }
                .id("composer-textarea")
                .overlay(alignment: .bottomLeading) {
                    if showCommandMenu && !commands.isEmpty {
                        CommandMenuView(
                            commands: commands,
                            selectedIndex: $commandMenuIndex,
                            onSelect: handleCommandSelect
                        )
                        .environmentObject(appState)
                        .offset(x: 0, y: 20)
                        .zIndex(10)
                    }
                }
                
                // Right: Actions
                if isSettingsMode {
                    TypewriterButton(variant: .dark) {
                        handleSubmit()
                    } label: {
                        Text("Apply")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .background(Color(hex: "#FAF7F2").opacity(0.5))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: "#E8E6DC"))
                .offset(y: -1),
            alignment: .bottom
        )
        .onAppear {
            if autoFocus {
                isFocused = true
            }
            text = initialText
            isTyping = !initialText.isEmpty
            startTypewriter()
        }
    }
    
    // MARK: - Components
    
    struct AnalyzingPill: View {
        var body: some View {
            HStack(spacing: 0) {
                Text("ANALYZING...")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.gray.opacity(0.3), .gray.opacity(0.6), .gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.5))
            )
        }
    }
    
    struct SectionSelectorView: View {
        @EnvironmentObject var appState: AppState
        @State private var isMenuOpen = false
        @Binding var selectedSectionId: String?
        @Binding var classifiedSectionId: String?
        @Binding var text: String
        
        var activeSectionId: String {
            selectedSectionId ?? classifiedSectionId ?? Utils.classifyNote(text)
        }
        
        var activeSection: Section {
            appState.sections.first { $0.id == activeSectionId } ?? appState.sections.first ?? Section(name: "Notes")
        }
        
        var body: some View {
            Button(action: {
                isMenuOpen.toggle()
            }) {
                HStack(spacing: 6) {
                    Text(activeSection.name)
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#F3F2EA"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#D1D1D1").opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isMenuOpen, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(appState.sections) { section in
                        Button(action: {
                            selectedSectionId = section.id
                            isMenuOpen = false
                        }) {
                            Text(section.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 192)
            }
        }
    }
    
    struct SettingsPill: View {
        var body: some View {
            Text("SETTINGS")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.gray.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
        }
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
    
    // MARK: - Helpers
    
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

    func moveCommandSelection(_ delta: Int) {
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

    func autocompleteCommand(_ command: Command) {
        guard let range = commandRange(in: text) else { return }
        let replacement = commandReplacement(for: command)
        text.replaceSubrange(range, with: replacement)
        showCommandMenu = false
        commandFilter = ""
        commandMenuIndex = 0
        switch command.action {
        case .settings:
            isSettingsMode = true
            text = ""
        default:
            break
        }
    }

    func commandReplacement(for command: Command) -> String {
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
    
    func startTypewriter() {
        guard !isTyping else { return }
        
        let currentText = Constants.placeholders[placeholderIndex]
        var currentPlaceholder = ""
        var isDeleting = false
        var isWaiting = false
        
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if isTyping {
                timer.invalidate()
                return
            }
            
            if !isDeleting && !isWaiting && currentPlaceholder.count < currentText.count {
                currentPlaceholder = String(currentText.prefix(currentPlaceholder.count + 1))
                placeholder = currentPlaceholder
            } else if !isDeleting && !isWaiting && currentPlaceholder == currentText {
                // Full text displayed, wait before starting to delete
                isWaiting = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    isWaiting = false
                    isDeleting = true
                }
            } else if isDeleting && !currentPlaceholder.isEmpty {
                currentPlaceholder = String(currentPlaceholder.dropLast())
                placeholder = currentPlaceholder
            } else if isDeleting && currentPlaceholder.isEmpty {
                isDeleting = false
                isWaiting = false
                placeholderIndex = (placeholderIndex + 1) % Constants.placeholders.count
                timer.invalidate()
                startTypewriter()
            }
        }
    }
    
    func handleTextChange(_ newValue: String) {
        text = newValue
        onTextChange?(newValue)
        isTyping = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
        
        // Parse user override commands: /task, /idea, /note, @Section
        let trimmedText = newValue.trimmingCharacters(in: .whitespaces)
        var userOverride: String? = nil
        
        // Check for explicit commands
        if trimmedText.hasPrefix("/task") || trimmedText.lowercased().hasPrefix("/tasks") {
            userOverride = "tasks"
            selectedSectionId = "tasks"
        } else if trimmedText.hasPrefix("/idea") || trimmedText.lowercased().hasPrefix("/ideas") {
            userOverride = "ideas"
            selectedSectionId = "ideas"
        } else if trimmedText.hasPrefix("/note") || trimmedText.lowercased().hasPrefix("/notes") {
            userOverride = "notes"
            selectedSectionId = "notes"
        } else {
            // Check for @SectionName content pattern (e.g., "@food momos")
            let sectionPattern = try! NSRegularExpression(pattern: #"@(\w+)\s+(.+)"#, options: [])
            let nsRange = NSRange(location: 0, length: trimmedText.utf16.count)
            if let match = sectionPattern.firstMatch(in: trimmedText, options: [], range: nsRange),
               match.numberOfRanges >= 3,
               let sectionRange = Range(match.range(at: 1), in: trimmedText),
               let contentRange = Range(match.range(at: 2), in: trimmedText) {
                let sectionName = String(trimmedText[sectionRange])
                let content = String(trimmedText[contentRange]).trimmingCharacters(in: .whitespaces)
                
                // Only proceed if there's actual content
                if !content.isEmpty {
                    // Check if section exists, if not, create it
                    if let existingSection = appState.sections.first(where: { $0.name.lowercased() == sectionName.lowercased() }) {
                        userOverride = existingSection.id
                        selectedSectionId = existingSection.id
                    } else {
                        // Section doesn't exist - create it
                        let sectionId = sectionName.lowercased().replacingOccurrences(of: " ", with: "-") + "-" + String(Int(Date().timeIntervalSince1970))
                        let newSection = Section(
                            id: sectionId,
                            name: sectionName,
                            createdAt: Date().timeIntervalSince1970,
                            updatedAt: Date().timeIntervalSince1970,
                            tags: nil,
                            description: nil,
                            isBookmarked: false
                        )
                        appState.sections.append(newSection)
                        appState.saveData()
                        userOverride = sectionId
                        selectedSectionId = sectionId
                    }
                }
            }
            
            // Check for @SectionName command (without content - just switching section)
            if let atMatch = trimmedText.range(of: #"@(\w+)"#, options: .regularExpression) {
                let sectionName = String(trimmedText[atMatch]).dropFirst() // Remove @
                if let matchingSection = appState.sections.first(where: { $0.name.lowercased() == sectionName.lowercased() }) {
                    userOverride = matchingSection.id
                    selectedSectionId = matchingSection.id
                }
            }
        }
        
        // Clear override if no command detected and no user override was set
        if userOverride == nil {
            selectedSectionId = nil
        }

        if !isSettingsMode && trimmedText.lowercased().hasPrefix("/settings") {
            isSettingsMode = true
            text = trimmedText.replacingOccurrences(of: #"/settings\s*"#, with: "", options: .regularExpression)
            showCommandMenu = false
            commandFilter = ""
            commandMenuIndex = 0
            return
        }
        
        // Detect slash command menu
        if !isSettingsMode && userOverride == nil {
            if let match = commandRange(in: newValue) {
                commandFilter = String(newValue[match]).dropFirst().trimmingCharacters(in: .whitespaces)
                commandMenuIndex = 0
                showCommandMenu = !commands.isEmpty
            } else {
                showCommandMenu = false
            }
        } else {
            showCommandMenu = false
        }
        
        // Real-time AI classification (only if no user override and text is substantial)
        if userOverride == nil && trimmedText.count > 2 && !isSettingsMode {
            // Cancel previous classification task
            aiClassificationTask?.cancel()
            
            // Debounce: wait 1 second after user stops typing
            isAnalyzing = true
            aiClassificationTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                guard !Task.isCancelled else { return }
                
                do {
                    let result = try await GroqService.shared.classifyNote(trimmedText, availableSections: appState.sections)
                    await MainActor.run {
                        classifiedSectionId = result.sectionId
                        classificationConfidence = result.confidence
                        isAnalyzing = false
                    }
                } catch {
                    // Fallback to keyword-based classification
                    await MainActor.run {
                        classifiedSectionId = Utils.classifyNote(trimmedText)
                        classificationConfidence = 0.5
                        isAnalyzing = false
                    }
                }
            }
        } else {
                isAnalyzing = false
            if userOverride != nil {
                // Clear AI classification when user overrides
                classifiedSectionId = nil
            }
        }
    }
    
    func handleCommandSelect(_ command: Command) {
        // Remove command text
        if let range = commandRange(in: text) {
            text = String(text[..<range.lowerBound])
        }
        showCommandMenu = false
        commandFilter = ""
        
        switch command.action {
        case .settings:
            isSettingsMode = true
        case .search:
            appState.pendingSearchQuery = text
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
            onTextChange?("")
        case .setSection(let id):
            selectedSectionId = id
        }
    }

    func commandRange(in value: String) -> Range<String.Index>? {
        if let match = value.range(of: #"/[a-zA-Z0-9\s]*$"#, options: .regularExpression) {
            return match
        }
        return nil
    }
    
    func handleSubmit() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        if !isSettingsMode && trimmedText.lowercased().hasPrefix("/settings") {
            isSettingsMode = true
            text = trimmedText.replacingOccurrences(of: #"/settings\s*"#, with: "", options: .regularExpression)
            showCommandMenu = false
            commandFilter = ""
            commandMenuIndex = 0
            return
        }

        if trimmedText.lowercased().hasPrefix("/connector") {
            let name = trimmedText.replacingOccurrences(of: #"/connector\s*"#, with: "", options: .regularExpression)
            appState.addConnector(name: name)
            text = ""
            onTextChange?("")
            return
        }

        if trimmedText.lowercased().hasPrefix("/search") {
            let query = trimmedText.replacingOccurrences(of: #"/search\s*"#, with: "", options: .regularExpression)
            appState.pendingSearchQuery = query
            text = ""
            onTextChange?("")
            return
        }

        if trimmedText.lowercased().hasPrefix("/import") {
            appState.currentView = .settings
            appState.shouldShowImportDialog = true
            text = ""
            onTextChange?("")
            return
        }

        if trimmedText.lowercased().hasPrefix("/new") {
            let content = trimmedText.replacingOccurrences(of: #"/new\s*"#, with: "", options: .regularExpression)
            appState.pendingContent = content
            appState.isNewSectionModalOpen = true
            text = ""
            onTextChange?("")
            return
        }
        
        if isSettingsMode {
            let setting = parseSettingsIntent(text)
            if let setting = setting {
                appState.updateSettings(type: setting.type, value: setting.value)
            }
            isSettingsMode = false
            text = ""
            onTextChange?("")
            return
        }
        
        // Clean up command text from input
        var cleanedText = text
        // Remove /task, /idea, /note commands
        cleanedText = cleanedText.replacingOccurrences(of: #"/task\s*"#, with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: #"/idea\s*"#, with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: #"/note\s*"#, with: "", options: .regularExpression)
        // Remove @SectionName content pattern (e.g., "@food momos" -> "momos")
        cleanedText = cleanedText.replacingOccurrences(of: #"@\w+\s+"#, with: "", options: .regularExpression)
        // Remove @SectionName commands (without content)
        cleanedText = cleanedText.replacingOccurrences(of: #"@\w+\s*"#, with: "", options: .regularExpression)
        cleanedText = cleanedText.trimmingCharacters(in: .whitespaces)
        
        guard !cleanedText.isEmpty else { return }
        
        appState.addNote(text: cleanedText, sectionId: activeSectionId)
        text = ""
        onTextChange?("")
        selectedSectionId = nil
        classifiedSectionId = nil
        isTyping = false
        isAnalyzing = false
        showCommandMenu = false
        aiClassificationTask?.cancel()
    }
    
    func parseSettingsIntent(_ input: String) -> (type: String, value: String)? {
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

    func extractConnectorName(_ input: String) -> String? {
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
}
