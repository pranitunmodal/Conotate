//
//  StorageManager.swift
//  ConotateMacOS
//

import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func saveSections(_ sections: [Section]) {
        if let encoded = try? JSONEncoder().encode(sections) {
            userDefaults.set(encoded, forKey: "conotate-sections")
        }
    }
    
    func loadSections() -> [Section] {
        guard let data = userDefaults.data(forKey: "conotate-sections"),
              let sections = try? JSONDecoder().decode([Section].self, from: data) else {
            return []
        }
        return sections
    }
    
    func saveNotes(_ notes: [Note]) {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: "conotate-notes")
        }
    }
    
    func loadNotes() -> [Note] {
        guard let data = userDefaults.data(forKey: "conotate-notes"),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            return []
        }
        return notes
    }
    
    func saveString(key: String, value: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func loadString(key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
}
