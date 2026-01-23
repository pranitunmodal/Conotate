//
//  SupabaseService.swift
//  ConotateMacOS
//
//  Based on official Supabase Swift SDK: https://supabase.com/docs/reference/swift/introduction
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private var client: SupabaseClient?
    
    // Supabase configuration - these should be set via environment variables or Config
    private let supabaseURL: String
    private let supabaseAnonKey: String
    
    private init() {
        // Get Supabase credentials from Config (environment variables or .env file)
        // Also check system environment (for Xcode scheme settings)
        supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? 
                     Config.shared.get("SUPABASE_URL") ?? ""
        supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? 
                         Config.shared.get("SUPABASE_ANON_KEY") ?? ""
        
        if !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty,
           let url = URL(string: supabaseURL) {
            // Initialize Supabase client per official docs:
            // https://supabase.com/docs/reference/swift/initializing
            client = SupabaseClient(supabaseURL: url, supabaseKey: supabaseAnonKey)
            print("✅ Supabase initialized successfully!")
            print("   URL: \(supabaseURL)")
            print("   Key: \(supabaseAnonKey.prefix(20))...")
        } else {
            print("⚠️ Supabase not configured:")
            print("   SUPABASE_URL: \(supabaseURL.isEmpty ? "❌ Missing" : "✅ Found")")
            print("   SUPABASE_ANON_KEY: \(supabaseAnonKey.isEmpty ? "❌ Missing" : "✅ Found")")
        }
    }
    
    var isConfigured: Bool {
        return client != nil && !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
    
    // MARK: - Authentication
    // Based on: https://supabase.com/docs/reference/swift/auth/sign-in-a-user
    
    func signIn(email: String, password: String) async throws -> String {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        // Official API: https://supabase.com/docs/reference/swift/auth/sign-in-a-user
        let session = try await client.auth.signIn(email: email, password: password)
        // Return user ID as string
        return session.user.id.uuidString
    }
    
    func signUp(email: String, password: String) async throws -> String {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        // Official API: https://supabase.com/docs/reference/swift/auth/create-a-new-user
        let session = try await client.auth.signUp(email: email, password: password)
        return session.user.id.uuidString
    }
    
    func signOut() async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        // Official API: https://supabase.com/docs/reference/swift/auth/sign-out-a-user
        try await client.auth.signOut()
    }
    
    func getCurrentUserId() async throws -> String? {
        guard let client = client else {
            return nil
        }
        // Official API: https://supabase.com/docs/reference/swift/auth/retrieve-a-user
        // Get the current session first, then extract user ID
        let session = try await client.auth.session
        return session.user.id.uuidString
    }
    
    // MARK: - Sections
    // Based on: https://supabase.com/docs/reference/swift/database/fetch-data
    
    func fetchSections(userId: String) async throws -> [Section] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        // Official API: https://supabase.com/docs/reference/swift/database/fetch-data
        // https://supabase.com/docs/reference/swift/database/using-filters
        // https://supabase.com/docs/reference/swift/database/order-the-results
        let response: [SectionRow] = try await client
            .from("sections")
            .select()
            .eq("user_id", value: userId)  // Filter: https://supabase.com/docs/reference/swift/database/column-is-equal-to-a-value
            .order("updated_at", ascending: false)  // Order: https://supabase.com/docs/reference/swift/database/order-the-results
            .execute()
            .value
        
        return response.map { $0.toSection() }
    }
    
    func createSection(_ section: Section, userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        let row = SectionRow.fromSection(section, userId: userId)
        // Official API: https://supabase.com/docs/reference/swift/database/insert-data
        try await client
            .from("sections")
            .insert(row)
            .execute()
    }
    
    func updateSection(_ section: Section, userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        let row = SectionRow.fromSection(section, userId: userId)
        // Official API: https://supabase.com/docs/reference/swift/database/update-data
        try await client
            .from("sections")
            .update(row)
            .eq("id", value: section.id)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func deleteSection(id: String, userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        // Official API: https://supabase.com/docs/reference/swift/database/delete-data
        try await client
            .from("sections")
            .delete()
            .eq("id", value: id)
            .eq("user_id", value: userId)
            .execute()
    }
    
    // MARK: - Notes
    // Based on: https://supabase.com/docs/reference/swift/database/fetch-data
    
    func fetchNotes(userId: String, sectionId: String? = nil) async throws -> [Note] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        // Official API: https://supabase.com/docs/reference/swift/database/fetch-data
        var query = client
            .from("notes")
            .select()
            .eq("user_id", value: userId)
        
        if let sectionId = sectionId {
            query = query.eq("section_id", value: sectionId)
        }
        
        let response: [NoteRow] = try await query
            .order("updated_at", ascending: false)
            .execute()
            .value
        
        return response.map { $0.toNote() }
    }
    
    func createNote(_ note: Note, userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        let row = NoteRow.fromNote(note, userId: userId)
        // Official API: https://supabase.com/docs/reference/swift/database/insert-data
        try await client
            .from("notes")
            .insert(row)
            .execute()
    }
    
    func updateNote(_ note: Note, userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        let row = NoteRow.fromNote(note, userId: userId)
        // Official API: https://supabase.com/docs/reference/swift/database/update-data
        try await client
            .from("notes")
            .update(row)
            .eq("id", value: note.id)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func deleteNote(id: String, userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        // Official API: https://supabase.com/docs/reference/swift/database/delete-data
        try await client
            .from("notes")
            .delete()
            .eq("id", value: id)
            .eq("user_id", value: userId)
            .execute()
    }
}

// MARK: - Database Row Models

struct SectionRow: Codable {
    let id: String
    let user_id: String
    let name: String
    let emoji: String?
    let tags: [String]?
    let description: String?
    let is_bookmarked: Bool?
    let created_at: String
    let updated_at: String
    
    func toSection() -> Section {
        Section(
            id: id,
            name: name,
            emoji: emoji,
            createdAt: ISO8601DateFormatter().date(from: created_at)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            updatedAt: ISO8601DateFormatter().date(from: updated_at)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            tags: tags,
            description: description,
            isBookmarked: is_bookmarked ?? false
        )
    }
    
    static func fromSection(_ section: Section, userId: String) -> SectionRow {
        let formatter = ISO8601DateFormatter()
        return SectionRow(
            id: section.id,
            user_id: userId,
            name: section.name,
            emoji: section.emoji,
            tags: section.tags,
            description: section.description,
            is_bookmarked: section.isBookmarked,
            created_at: formatter.string(from: Date(timeIntervalSince1970: section.createdAt)),
            updated_at: formatter.string(from: Date(timeIntervalSince1970: section.updatedAt))
        )
    }
}

struct NoteRow: Codable {
    let id: String
    let user_id: String
    let section_id: String
    let text: String
    let tags: [String]?
    let created_at: String
    let updated_at: String
    
    func toNote() -> Note {
        Note(
            id: id,
            text: text,
            sectionId: section_id,
            createdAt: ISO8601DateFormatter().date(from: created_at)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            updatedAt: ISO8601DateFormatter().date(from: updated_at)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            tags: tags
        )
    }
    
    static func fromNote(_ note: Note, userId: String) -> NoteRow {
        let formatter = ISO8601DateFormatter()
        return NoteRow(
            id: note.id,
            user_id: userId,
            section_id: note.sectionId,
            text: note.text,
            tags: note.tags,
            created_at: formatter.string(from: Date(timeIntervalSince1970: note.createdAt)),
            updated_at: formatter.string(from: Date(timeIntervalSince1970: note.updatedAt))
        )
    }
}

enum SupabaseError: Error {
    case notConfigured
    case authenticationFailed
    case networkError
    case invalidResponse
}
