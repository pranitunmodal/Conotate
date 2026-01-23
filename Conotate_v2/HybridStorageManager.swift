//
//  HybridStorageManager.swift
//  ConotateMacOS
//
//  This manager uses Supabase (cloud backend) when configured,
//  otherwise falls back to local storage (UserDefaults)
//

import Foundation

class HybridStorageManager {
    static let shared = HybridStorageManager()
    private let localStorage = StorageManager.shared
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Sections
    
    func saveSections(_ sections: [Section], userId: String) {
        // If Supabase is configured, save to cloud
        if supabaseService.isConfigured {
            print("☁️ Saving \(sections.count) sections to Supabase...")
            Task {
                do {
                    // Delete all existing sections and recreate (simple sync strategy)
                    // In production, you'd want more sophisticated sync
                    let existingSections = try await supabaseService.fetchSections(userId: userId)
                    print("   Found \(existingSections.count) existing sections in Supabase")
                    for section in existingSections {
                        try? await supabaseService.deleteSection(id: section.id, userId: userId)
                    }
                    
                    // Create all sections
                    for section in sections {
                        try? await supabaseService.createSection(section, userId: userId)
                    }
                    print("✅ Successfully saved \(sections.count) sections to Supabase")
                } catch {
                    print("⚠️ Failed to save sections to Supabase: \(error)")
                    // Fallback to local storage
                    localStorage.saveSections(sections, userId: userId)
                }
            }
        } else {
            print("💾 Saving \(sections.count) sections to local storage (Supabase not configured)")
            // Fallback to local storage
            localStorage.saveSections(sections, userId: userId)
        }
    }
    
    func loadSections(userId: String) async -> [Section] {
        // If Supabase is configured, load from cloud
        if supabaseService.isConfigured {
            print("☁️ Loading sections from Supabase...")
            do {
                let sections = try await supabaseService.fetchSections(userId: userId)
                print("✅ Loaded \(sections.count) sections from Supabase")
                return sections
            } catch {
                print("⚠️ Failed to load sections from Supabase: \(error)")
                // Fallback to local storage
                return localStorage.loadSections(userId: userId)
            }
        } else {
            print("💾 Loading sections from local storage (Supabase not configured)")
            // Use local storage
            return localStorage.loadSections(userId: userId)
        }
    }
    
    // MARK: - Notes
    
    func saveNotes(_ notes: [Note], userId: String) {
        // If Supabase is configured, save to cloud
        if supabaseService.isConfigured {
            print("☁️ Saving \(notes.count) notes to Supabase...")
            Task {
                do {
                    // Delete all existing notes and recreate (simple sync strategy)
                    let existingNotes = try await supabaseService.fetchNotes(userId: userId)
                    print("   Found \(existingNotes.count) existing notes in Supabase")
                    for note in existingNotes {
                        try? await supabaseService.deleteNote(id: note.id, userId: userId)
                    }
                    
                    // Create all notes
                    for note in notes {
                        try? await supabaseService.createNote(note, userId: userId)
                    }
                    print("✅ Successfully saved \(notes.count) notes to Supabase")
                } catch {
                    print("⚠️ Failed to save notes to Supabase: \(error)")
                    // Fallback to local storage
                    localStorage.saveNotes(notes, userId: userId)
                }
            }
        } else {
            print("💾 Saving \(notes.count) notes to local storage (Supabase not configured)")
            // Fallback to local storage
            localStorage.saveNotes(notes, userId: userId)
        }
    }
    
    func loadNotes(userId: String) async -> [Note] {
        // If Supabase is configured, load from cloud
        if supabaseService.isConfigured {
            print("☁️ Loading notes from Supabase...")
            do {
                let notes = try await supabaseService.fetchNotes(userId: userId)
                print("✅ Loaded \(notes.count) notes from Supabase")
                return notes
            } catch {
                print("⚠️ Failed to load notes from Supabase: \(error)")
                // Fallback to local storage
                return localStorage.loadNotes(userId: userId)
            }
        } else {
            print("💾 Loading notes from local storage (Supabase not configured)")
            // Use local storage
            return localStorage.loadNotes(userId: userId)
        }
    }
    
    // MARK: - Single Note Operations (for real-time updates)
    
    func createNote(_ note: Note, userId: String) async throws {
        if supabaseService.isConfigured {
            print("☁️ Creating note in Supabase: \(note.text.prefix(50))...")
            try await supabaseService.createNote(note, userId: userId)
            print("✅ Note created in Supabase")
        } else {
            print("💾 Creating note in local storage (Supabase not configured)")
            var notes = localStorage.loadNotes(userId: userId)
            notes.insert(note, at: 0)
            localStorage.saveNotes(notes, userId: userId)
        }
    }
    
    func updateNote(_ note: Note, userId: String) async throws {
        if supabaseService.isConfigured {
            try await supabaseService.updateNote(note, userId: userId)
        } else {
            var notes = localStorage.loadNotes(userId: userId)
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index] = note
                localStorage.saveNotes(notes, userId: userId)
            }
        }
    }
    
    func deleteNote(id: String, userId: String) async throws {
        if supabaseService.isConfigured {
            try await supabaseService.deleteNote(id: id, userId: userId)
        } else {
            var notes = localStorage.loadNotes(userId: userId)
            notes.removeAll { $0.id == id }
            localStorage.saveNotes(notes, userId: userId)
        }
    }
    
    // MARK: - String Storage (for user preferences)
    
    func saveString(key: String, value: String, userId: String? = nil) {
        // User preferences stay in local storage for now
        // (Supabase can be used for user settings if needed)
        localStorage.saveString(key: key, value: value, userId: userId)
    }
    
    func loadString(key: String, userId: String? = nil) -> String? {
        return localStorage.loadString(key: key, userId: userId)
    }
}
