//
//  AppState.swift
//  ConotateMacOS
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var sections: [Section] = []
    @Published var notes: [Note] = []
    @Published var isNewSectionModalOpen = false
    @Published var pendingContent = ""
    
    // Authentication State
    @Published var isAuthenticated = false
    @Published var currentUserEmail: String? = nil
    
    // Theme & User State
    @Published var themeColor: Color = Color(hex: "#FAF7F2")
    @Published var isDarkMode = false
    @Published var userName = "Creator"
    @Published var userAvatar = "👨‍🎨"
    
    // Computed property to get display name from email
    var displayName: String {
        guard let email = currentUserEmail else {
            return userName
        }
        // Extract first name from email (e.g., "varun@unmodal.com" -> "Varun")
        // Handle cases like "temp.pranit@unmodal.com" -> "Pranit"
        let emailPrefix = email.components(separatedBy: "@").first ?? ""
        let nameParts = emailPrefix.components(separatedBy: ".")
        // Get the last part (actual first name) and capitalize it
        let firstName = nameParts.last ?? emailPrefix
        return firstName.prefix(1).uppercased() + firstName.dropFirst().lowercased()
    }
    
    // Screen & View State
    @Published var currentView: ScreenView = .home
    @Published var bottomPanelView: ViewState = .expanded
    @Published var pulseSectionId: String? = nil
    
    // Search State
    @Published var pendingSearchQuery = ""
    @Published var searchQuery: String = ""
    
    // Detailed Modal State
    @Published var expandedSectionId: String? = nil
    
    // Animation State
    @Published var flyingNote: FlyingNoteState? = nil
    
    private let storage = HybridStorageManager.shared
    private let localStorage = StorageManager.shared // For backward compatibility
    
    init() {
        // Check if user was previously authenticated
        if let savedEmail = storage.loadString(key: "conotate-user-email"), !savedEmail.isEmpty {
            // Check if we have a Supabase session
            if SupabaseService.shared.isConfigured {
                Task {
                    do {
                        // Try to get current user from Supabase
                        if let supabaseUserId = try await SupabaseService.shared.getCurrentUserId() {
                            // User is still authenticated in Supabase
                            await MainActor.run {
                            isAuthenticated = true
                            currentUserEmail = savedEmail
                            loadData(supabaseUserId: supabaseUserId)
                            }
                        } else {
                            // No Supabase session, clear auth state
                            await MainActor.run {
                                isAuthenticated = false
                                currentUserEmail = nil
                                storage.saveString(key: "conotate-user-email", value: "")
                            }
                        }
                    } catch {
                        // Supabase session expired or invalid
                        await MainActor.run {
                            isAuthenticated = false
                            currentUserEmail = nil
                            storage.saveString(key: "conotate-user-email", value: "")
                        }
                    }
                }
            } else {
                // Supabase not configured, use local auth (backward compatibility)
                isAuthenticated = true
                currentUserEmail = savedEmail
                loadData()
            }
        }
        updateDarkMode()
    }
    
    func loadData(supabaseUserId: String? = nil) {
        guard let email = currentUserEmail else {
            // Clear data if no user is logged in
            sections = []
            notes = []
            return
        }
        
        // Use Supabase user ID if available, otherwise fall back to normalized email
        let userId: String
        if let supabaseId = supabaseUserId ?? storage.loadString(key: "conotate-supabase-user-id") {
            userId = supabaseId
        } else {
            // Fallback for backward compatibility
            userId = email.lowercased().replacingOccurrences(of: "@", with: "-").replacingOccurrences(of: ".", with: "-")
        }
        
        // For local storage (API keys, preferences), still use normalized email
        let normalizedEmail = email.lowercased().replacingOccurrences(of: "@", with: "-").replacingOccurrences(of: ".", with: "-")
        
        // Load data asynchronously from Supabase (or local storage)
        Task {
            let loadedSections = await storage.loadSections(userId: userId)
            let loadedNotes = await storage.loadNotes(userId: userId)
            
            await MainActor.run {
                sections = loadedSections.isEmpty ? Constants.defaultSections : loadedSections
                
                // Ensure Unsorted section exists
                if !sections.contains(where: { $0.id == "unsorted" }) {
                    if let unsortedTemplate = Constants.defaultSections.first(where: { $0.id == "unsorted" }) {
                        sections.append(unsortedTemplate)
                    }
                }
                
                notes = loadedNotes.isEmpty ? Constants.initialNotes : loadedNotes
                
                userName = storage.loadString(key: "conotate-user-name", userId: normalizedEmail) ?? "Creator"
                userAvatar = storage.loadString(key: "conotate-user-avatar", userId: normalizedEmail) ?? "👨‍🎨"
                
                let savedColor = storage.loadString(key: "conotate-theme-color", userId: normalizedEmail) ?? "#FAF7F2"
                themeColor = Color(hex: savedColor)
                updateDarkMode()
            }
        }
    }
    
    func saveData() {
        guard let email = currentUserEmail else {
            return // Don't save if no user is logged in
        }
        
        // Use Supabase user ID if available, otherwise fall back to normalized email
        let userId: String
        if let supabaseId = storage.loadString(key: "conotate-supabase-user-id") {
            userId = supabaseId
        } else {
            // Fallback for backward compatibility
            userId = email.lowercased().replacingOccurrences(of: "@", with: "-").replacingOccurrences(of: ".", with: "-")
        }
        
        // For local storage (preferences), use normalized email
        let normalizedEmail = email.lowercased().replacingOccurrences(of: "@", with: "-").replacingOccurrences(of: ".", with: "-")
        
        storage.saveSections(sections, userId: userId)
        storage.saveNotes(notes, userId: userId)
        storage.saveString(key: "conotate-user-name", value: userName, userId: normalizedEmail)
        storage.saveString(key: "conotate-user-avatar", value: userAvatar, userId: normalizedEmail)
        storage.saveString(key: "conotate-theme-color", value: themeColor.toHex(), userId: normalizedEmail)
    }
    
    func updateDarkMode() {
        isDarkMode = Utils.isColorDark(themeColor)
    }
    
    func addNote(text: String, sectionId: String) {
        let newNote = Note(
            text: text,
            sectionId: sectionId,
            createdAt: Date().timeIntervalSince1970,
            updatedAt: Date().timeIntervalSince1970
        )
        notes.insert(newNote, at: 0)
        
        // Save to Supabase (or local storage)
        Task {
            guard let email = currentUserEmail else { return }
            // Use Supabase user ID if available, otherwise fall back to normalized email
            let userId: String
            if let supabaseId = storage.loadString(key: "conotate-supabase-user-id") {
                userId = supabaseId
            } else {
                userId = email.lowercased().replacingOccurrences(of: "@", with: "-").replacingOccurrences(of: ".", with: "-")
            }
            try? await storage.createNote(newNote, userId: userId)
        }
        
        saveData() // Also save locally for immediate UI update
        
        // Optionally use Groq to enhance section description
        Task {
            if let section = sections.first(where: { $0.id == sectionId }) {
                let sectionNotes = notes.filter { $0.sectionId == sectionId }
                let newDescription = await Utils.generateDescriptionWithGroq(notes: sectionNotes, sectionName: section.name)
                if let index = sections.firstIndex(where: { $0.id == sectionId }) {
                    sections[index].description = newDescription
                    sections[index].updatedAt = Date().timeIntervalSince1970
                    saveData()
                }
            }
        }
    }
    
    func triggerFlyingNote(text: String, sectionId: String) {
        // This will be handled by the view
        let displayText = text.count > 40 ? String(text.prefix(40)) + "..." : text
        flyingNote = FlyingNoteState(
            id: UUID().uuidString,
            text: displayText,
            targetSectionId: sectionId
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.flyingNote = nil
            self.pulseSectionId = sectionId
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.pulseSectionId = nil
            }
        }
    }
    
    func createNewSection(title: String, tags: [String], content: String) {
        let sectionId = title.lowercased().replacingOccurrences(of: " ", with: "-") + "-" + String(Int(Date().timeIntervalSince1970))
        let newSection = Section(
            id: sectionId,
            name: title,
            createdAt: Date().timeIntervalSince1970,
            updatedAt: Date().timeIntervalSince1970,
            tags: tags,
            description: "A new section for \(title).",
            isBookmarked: false
        )
        sections.append(newSection)
        saveData()
        
        if !content.trimmingCharacters(in: .whitespaces).isEmpty {
            addNote(text: content, sectionId: sectionId)
        }
    }
    
    func updateSection(id: String, updates: Section.PartialSection) {
        if let index = sections.firstIndex(where: { $0.id == id }) {
            var updated = sections[index]
            if let name = updates.name { updated.name = name }
            if let tags = updates.tags { updated.tags = tags }
            if let description = updates.description { updated.description = description }
            updated.updatedAt = Date().timeIntervalSince1970
            sections[index] = updated
            saveData()
        }
    }
    
    func updateNote(id: String, text: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].text = text
            notes[index].updatedAt = Date().timeIntervalSince1970
            saveData()
        }
    }
    
    func updateNoteSection(id: String, sectionId: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].sectionId = sectionId
            notes[index].updatedAt = Date().timeIntervalSince1970
            saveData()
        }
    }
    
    func deleteSection(id: String, exportFirst: Bool) {
        if exportFirst {
            if let section = sections.first(where: { $0.id == id }) {
                let sectionNotes = notes.filter { $0.sectionId == id }
                Utils.exportSectionAsText(section: section, notes: sectionNotes)
            }
        }
        sections.removeAll { $0.id == id }
        notes.removeAll { $0.sectionId == id }
        if expandedSectionId == id {
            expandedSectionId = nil
        }
        saveData()
    }
    
    func toggleBookmark(id: String) {
        if let index = sections.firstIndex(where: { $0.id == id }) {
            sections[index].isBookmarked = !(sections[index].isBookmarked ?? false)
            saveData()
        }
    }
    
    func exportData() {
        let data: [String: Any] = [
            "sections": sections.map { $0.toDictionary() },
            "notes": notes.map { $0.toDictionary() }
        ]
        Utils.exportJSON(data: data, filename: "conotate-backup-\(Int(Date().timeIntervalSince1970)).json")
    }
    
    func importData(json: String) {
        if let data = json.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sectionsData = jsonObject["sections"] as? [[String: Any]],
           let notesData = jsonObject["notes"] as? [[String: Any]] {
            
            sections = sectionsData.compactMap { Section.fromDictionary($0) }
            notes = notesData.compactMap { Note.fromDictionary($0) }
            saveData()
        }
    }
    
    func updateSettings(type: String, value: String) {
        switch type {
        case "theme":
            if value.lowercased() == "dark mode" {
                themeColor = Color(hex: "#1A1A1A")
            } else if value.lowercased() == "light mode" {
                themeColor = Color(hex: "#FAF7F2")
            } else {
                themeColor = Color(hex: value)
            }
            updateDarkMode()
        case "name":
            userName = value
        case "avatar":
            userAvatar = value
        default:
            break
        }
        saveData()
    }
    
    func signUp(email: String, password: String) async throws {
        // Use Supabase Auth - no fallback to hardcoded credentials
        guard SupabaseService.shared.isConfigured else {
            throw LoginError.supabaseNotConfigured
        }
        
        // Sign up with Supabase Auth
        let supabaseUserId = try await SupabaseService.shared.signUp(email: email, password: password)
        
        // Clear current data before loading new user's data
        sections = []
        notes = []
        
        isAuthenticated = true
        currentUserEmail = email
        storage.saveString(key: "conotate-user-email", value: email)
        storage.saveString(key: "conotate-supabase-user-id", value: supabaseUserId)
        
        // Load the new user's data using Supabase user ID
        loadData(supabaseUserId: supabaseUserId)
    }
    
    func login(email: String, password: String) async throws {
        // Use Supabase Auth - no fallback to hardcoded credentials
        guard SupabaseService.shared.isConfigured else {
            throw LoginError.supabaseNotConfigured
        }
        
        // Sign in with Supabase Auth
        let supabaseUserId = try await SupabaseService.shared.signIn(email: email, password: password)
        
        // Clear current data before loading new user's data
        sections = []
        notes = []
        
        isAuthenticated = true
        currentUserEmail = email
        storage.saveString(key: "conotate-user-email", value: email)
        storage.saveString(key: "conotate-supabase-user-id", value: supabaseUserId)
        
        // Load the new user's data using Supabase user ID
        loadData(supabaseUserId: supabaseUserId)
    }
    
    enum LoginError: Error, LocalizedError {
        case supabaseNotConfigured
        case invalidCredentials
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .supabaseNotConfigured:
                return "Supabase is not configured. Please check your settings."
            case .invalidCredentials:
                return "Invalid email or password"
            case .networkError:
                return "Network error. Please check your connection."
            }
        }
    }
    
    func logout() {
        // Save current user's data before logging out
        saveData()
        
        // Sign out from Supabase if configured
        if SupabaseService.shared.isConfigured {
            Task {
                try? await SupabaseService.shared.signOut()
            }
        }
        
        isAuthenticated = false
        currentUserEmail = nil
        storage.saveString(key: "conotate-user-email", value: "")
        storage.saveString(key: "conotate-supabase-user-id", value: "")
        
        // Clear the in-memory data
        sections = []
        notes = []
        userName = "Creator"
        userAvatar = "👨‍🎨"
        themeColor = Color(hex: "#FAF7F2")
        
        updateDarkMode()
    }
}

struct FlyingNoteState: Identifiable {
    let id: String
    let text: String
    let targetSectionId: String
}

// Extensions for Codable conversion
extension Section {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        if let emoji = emoji { dict["emoji"] = emoji }
        if let tags = tags { dict["tags"] = tags }
        if let description = description { dict["description"] = description }
        if let isBookmarked = isBookmarked { dict["isBookmarked"] = isBookmarked }
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Section? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let createdAt = dict["createdAt"] as? TimeInterval,
              let updatedAt = dict["updatedAt"] as? TimeInterval else {
            return nil
        }
        return Section(
            id: id,
            name: name,
            emoji: dict["emoji"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: dict["tags"] as? [String],
            description: dict["description"] as? String,
            isBookmarked: dict["isBookmarked"] as? Bool ?? false
        )
    }
}

extension Note {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "text": text,
            "sectionId": sectionId,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        if let tags = tags { dict["tags"] = tags }
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Note? {
        guard let id = dict["id"] as? String,
              let text = dict["text"] as? String,
              let sectionId = dict["sectionId"] as? String,
              let createdAt = dict["createdAt"] as? TimeInterval,
              let updatedAt = dict["updatedAt"] as? TimeInterval else {
            return nil
        }
        return Note(
            id: id,
            text: text,
            sectionId: sectionId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: dict["tags"] as? [String]
        )
    }
}
