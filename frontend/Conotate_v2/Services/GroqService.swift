//
//  GroqService.swift
//  ConotateMacOS
//

import Foundation

struct ClassificationResult {
    let sectionId: String
    let confidence: Double
}

class GroqService {
    static let shared = GroqService()
    
    private init() {}
    
    // Get access token for Edge Function authentication
    private func getAccessToken() async throws -> String {
        guard let token = try await SupabaseService.shared.getAccessToken() else {
            throw GroqError.authenticationRequired
        }
        return token
    }
    
    // Get Supabase anon key for Edge Function authentication
    private func getSupabaseAnonKey() -> String {
        return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? 
               Config.shared.get("SUPABASE_ANON_KEY") ?? ""
    }
    
    // Get Edge Function URL
    private func getEdgeFunctionURL(functionName: String) -> String? {
        guard SupabaseService.shared.isConfigured else {
            return nil
        }
        let baseURL = SupabaseService.shared.edgeFunctionURL
        // Remove /groq-proxy and add the function name
        return baseURL.replacingOccurrences(of: "/groq-proxy", with: "/\(functionName)")
    }
    
    // Classify a note using the backend Edge Function
    func classifyNote(_ text: String, availableSections: [Section]) async throws -> ClassificationResult {
        guard let edgeURL = getEdgeFunctionURL(functionName: "classify-note") else {
            throw GroqError.supabaseNotConfigured
        }
        
        guard let url = URL(string: edgeURL) else {
            throw GroqError.invalidURL
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "text": text,
            "availableSections": availableSections.map { ["id": $0.id, "name": $0.name] }
        ]
        
        let accessToken = try await getAccessToken()
        let supabaseAnonKey = getSupabaseAnonKey()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if !supabaseAnonKey.isEmpty {
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Classification Edge Function error (\(httpResponse.statusCode)): \(errorText)")
            throw GroqError.invalidResponse
        }
        
        // Parse response
        struct ClassificationResponse: Codable {
            let sectionId: String
            let confidence: Double
        }
        
        let classificationResponse = try JSONDecoder().decode(ClassificationResponse.self, from: data)
        return ClassificationResult(
            sectionId: classificationResponse.sectionId,
            confidence: classificationResponse.confidence
        )
    }
    
    // Generate description for a section using the backend Edge Function
    func generateDescription(for notes: [Note], sectionName: String) async throws -> String {
        guard !notes.isEmpty else {
            return "This is the \(sectionName) section. Add notes to generate a summary."
        }
        
        guard let edgeURL = getEdgeFunctionURL(functionName: "generate-description") else {
            throw GroqError.supabaseNotConfigured
        }
        
        guard let url = URL(string: edgeURL) else {
            throw GroqError.invalidURL
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "notes": notes.map { ["text": $0.text] },
            "sectionName": sectionName
        ]
        
        // Get fresh access token
        let accessToken = try await getAccessToken()
        let supabaseAnonKey = getSupabaseAnonKey()
        
        // Debug logging
        print("🔑 generate-description: URL=\(edgeURL)")
        print("🔑 generate-description: Token prefix=\(accessToken.prefix(20))...")
        print("🔑 generate-description: Has apikey=\(!supabaseAnonKey.isEmpty)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if !supabaseAnonKey.isEmpty {
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Description Edge Function error (\(httpResponse.statusCode)): \(errorText)")
            throw GroqError.invalidResponse
        }
        
        // Parse response
        struct DescriptionResponse: Codable {
            let description: String
        }
        
        let descriptionResponse = try JSONDecoder().decode(DescriptionResponse.self, from: data)
        return descriptionResponse.description
    }
}

enum GroqError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case supabaseNotConfigured
    case authenticationRequired
}
