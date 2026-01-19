//
//  StorageManager.swift
//  ConotateMacOS
//

import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // Helper to create user-specific keys
    private func userKey(_ baseKey: String, userId: String) -> String {
        return "conotate-\(userId)-\(baseKey)"
    }
    
    func saveSections(_ sections: [Section], userId: String) {
        if let encoded = try? JSONEncoder().encode(sections) {
            userDefaults.set(encoded, forKey: userKey("sections", userId: userId))
        }
    }
    
    func loadSections(userId: String) -> [Section] {
        guard let data = userDefaults.data(forKey: userKey("sections", userId: userId)),
              let sections = try? JSONDecoder().decode([Section].self, from: data) else {
            return []
        }
        return sections
    }
    
    func saveNotes(_ notes: [Note], userId: String) {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: userKey("notes", userId: userId))
        }
    }
    
    func loadNotes(userId: String) -> [Note] {
        guard let data = userDefaults.data(forKey: userKey("notes", userId: userId)),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            return []
        }
        return notes
    }
    
    func saveString(key: String, value: String, userId: String? = nil) {
        let storageKey = userId != nil ? userKey(key, userId: userId!) : key
        userDefaults.set(value, forKey: storageKey)
    }
    
    func loadString(key: String, userId: String? = nil) -> String? {
        let storageKey = userId != nil ? userKey(key, userId: userId!) : key
        return userDefaults.string(forKey: storageKey)
    }
}
