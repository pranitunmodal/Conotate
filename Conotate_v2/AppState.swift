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
    
    // Screen & View State
    @Published var currentView: ScreenView = .home
    @Published var bottomPanelView: ViewState = .expanded
    @Published var pulseSectionId: String? = nil
    
    // Search State
    @Published var pendingSearchQuery = ""
    
    // Detailed Modal State
    @Published var expandedSectionId: String? = nil
    
    // Animation State
    @Published var flyingNote: FlyingNoteState? = nil
    
    private let storage = StorageManager.shared
    
    init() {
        // Check if user was previously authenticated
        if let savedEmail = storage.loadString(key: "conotate-user-email") {
            isAuthenticated = true
            currentUserEmail = savedEmail
            loadData()
        }
        updateDarkMode()
    }
    
    func loadData() {
        guard let userId = currentUserEmail else {
            // Clear data if no user is logged in
            sections = []
            notes = []
            return
        }
        
        let normalizedUserId = userId.lowercased().replacingOccurrences(of: "@", with: "-").replacingOccurrences(of: ".", with: "-")
        
        sections = storage.loadSections(userId: normalizedUserId)
        if sections.isEmpty {
            sections = Constants.defaultSections
        }
        
        // Ensure Unsorted section exists
        if !sections.contains(where: { $0.id == "unsorted" }) {
            if let unsortedTemplate = Constants.defaultSections.first(where: { $0.id == "unsorted" }) {
                sections.append(unsortedTemplate)
            }
        }
        
        notes = storage.loadNotes(userId: normalizedUserId)
        if notes.isEmpty {
            notes = Constants.initialNotes
        }
        
        userName = storage.loadString(key: "conotate-user-name", userId: normalizedUserId) ?? "Creator"
        userAvatar = storage.loadString(key: "conotate-user-avatar", userId: normalizedUserId) ?? "👨‍🎨"
        
        let savedColor = storage.loadString(key: "conotate-theme-color", userId: normalizedUserId) ?? "#FAF7F2"
        themeColor = Color(hex: savedColor)
        updateDarkMode()
    }
    
    func saveData() {
        guard let userId = currentUserEmail else {
            return // Don't save if no user is logged in
        }
        
        let normalizedUserId = userId.lowercased().replacingOccurrences(of: "@", with: "-").replacingOccurrences(of: ".", with: "-")
        
        storage.saveSections(sections, userId: normalizedUserId)
        storage.saveNotes(notes, userId: normalizedUserId)
        storage.saveString(key: "conotate-user-name", value: userName, userId: normalizedUserId)
        storage.saveString(key: "conotate-user-avatar", value: userAvatar, userId: normalizedUserId)
        storage.saveString(key: "conotate-theme-color", value: themeColor.toHex(), userId: normalizedUserId)
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
        saveData()
        
        // Trigger flying note animation
        triggerFlyingNote(text: text, sectionId: sectionId)
        
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
    
    func login(email: String, password: String) -> Bool {
        let validCredentials = [
            ("varun@unmodal.com", "testacc1"),
            ("jamie@unmodal.com", "testacc2"),
            ("sky@unmodal.com", "testacc3"),
            ("temp.pranit@unmodal.com", "testacc4")
        ]
        
        if validCredentials.contains(where: { $0.0 == email && $0.1 == password }) {
            // Clear current data before loading new user's data
            sections = []
            notes = []
            
            isAuthenticated = true
            currentUserEmail = email
            storage.saveString(key: "conotate-user-email", value: email)
            
            // Load the new user's data
            loadData()
            return true
        }
        return false
    }
    
    func logout() {
        // Save current user's data before logging out
        saveData()
        
        isAuthenticated = false
        currentUserEmail = nil
        storage.saveString(key: "conotate-user-email", value: "")
        
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
