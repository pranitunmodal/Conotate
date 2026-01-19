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
    
    private var apiKey: String {
        // Try to get from environment variable or .env file
        let envKey = Config.shared.get("GROQ_API_KEY")
        
        // Debug: Print what we found
        print("🔍 Looking for GROQ_API_KEY...")
        print("   Config.shared.get('GROQ_API_KEY') = \(envKey ?? "nil")")
        print("   System environment GROQ_API_KEY = \(ProcessInfo.processInfo.environment["GROQ_API_KEY"] ?? "nil")")
        
        if let key = envKey, !key.isEmpty {
            print("✅ Found API key (length: \(key.count))")
            return key
        }
        
        // No fallback - API key must be set via environment variable
        // This prevents accidentally committing secrets
        print("❌ GROQ_API_KEY not found!")
        fatalError("GROQ_API_KEY environment variable is not set. Please set it in your environment or .env file.")
    }
    
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    
    private init() {}
    
    func generateDescription(for notes: [Note], sectionName: String) async throws -> String {
        guard !notes.isEmpty else {
            return "This is the \(sectionName) section. Add notes to generate a summary."
        }
        
        let notesText = notes.prefix(5).map { $0.text }.joined(separator: "\n")
        let prompt = """
        Based on these notes from the "\(sectionName)" section, generate a brief, natural description (1-2 sentences):
        
        \(notesText)
        
        Description:
        """
        
        guard let url = URL(string: baseURL) else {
            throw GroqError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 100,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GroqError.invalidResponse
        }
        
        struct GroqResponse: Codable {
            let choices: [Choice]
            
            struct Choice: Codable {
                let message: Message
                
                struct Message: Codable {
                    let content: String
                }
            }
        }
        
        let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)
        return groqResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "A collection of notes about \(sectionName)."
    }
    
    func classifyNote(_ text: String, availableSections: [Section]) async throws -> ClassificationResult {
        // Parse commands first
        let (cleanText, forcedCategory, _) = parseCommands(text, availableSections: availableSections)
        
        if let forced = forcedCategory {
            return ClassificationResult(sectionId: forced, confidence: 1.0)
        }
        
        // Classify with AI
        let aiResult = try await classifyWithAI(cleanText, availableSections: availableSections)
        return aiResult
    }
    
    private func classifyWithAI(_ text: String, availableSections: [Section]) async throws -> ClassificationResult {
        guard let url = URL(string: baseURL) else {
            throw GroqError.invalidURL
        }
        
        let systemPrompt = """
You are a classification assistant for a personal organization app.
Classify the user's input into one of these categories:
- "task": Actionable items, todos, reminders, things to do
- "idea": Creative thoughts, possibilities, brainstorming, "what if" scenarios, imaginative concepts
- "note": Information to remember, facts, meeting notes, summaries
- "unsorted": When unclear, gibberish, ambiguous, or doesn't fit other categories

CRITICAL RULES:
1. If text is gibberish (not real words/phrases like "adhcfsbjhd", "zidwudd") → "unsorted" with confidence < 0.6
2. If text is ambiguous (single words like "banana" without context) → "unsorted" with confidence < 0.6
3. If text doesn't clearly fit any category → "unsorted" with confidence < 0.6
4. Creative/whimsical concepts (e.g., "cat powered laundry") → "idea" with high confidence
5. Action items (e.g., "get eggs") → "task" with high confidence
6. Information/facts (e.g., "Meeting at 3pm") → "note" with high confidence

Respond ONLY with valid JSON in this exact format:
{"category": "task|idea|note|unsorted", "confidence": 0.0-1.0}
"""
        
        let requestBody: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "max_tokens": 150,
            "temperature": 0.1
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GroqError.invalidResponse
        }
        
        // Decode response using Codable
        struct GroqResponse: Codable {
            let choices: [Choice]
            
            struct Choice: Codable {
                let message: Message
                
                struct Message: Codable {
                    let content: String
                }
            }
        }
        
        let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)
        let content = groqResponse.choices.first?.message.content ?? ""
        
        // Parse JSON from the response (may have extra text)
        let jsonString = extractJSON(from: content)
        guard let jsonData = jsonString.data(using: .utf8) else {
            return fallbackClassification(text, availableSections: availableSections)
        }
        
        struct AIClassificationResult: Codable {
            let category: String
            let confidence: Double
        }
        
        let aiResult = try JSONDecoder().decode(AIClassificationResult.self, from: jsonData)
        
        // Validate the category
        guard !aiResult.category.isEmpty else {
            return fallbackClassification(text, availableSections: availableSections)
        }
        
        // Ensure confidence is in valid range
        let validatedConfidence = max(0.0, min(1.0, aiResult.confidence))
        
        // Map category to section ID
        let categoryLower = aiResult.category.lowercased()
        var sectionId: String
        
        if categoryLower == "task" || categoryLower == "tasks" {
            sectionId = "tasks"
        } else if categoryLower == "idea" || categoryLower == "ideas" {
            sectionId = "ideas"
        } else if categoryLower == "note" || categoryLower == "notes" {
            sectionId = "notes"
        } else if categoryLower == "unsorted" {
            sectionId = "unsorted"
        } else {
            // Try to find matching user-defined section
            if let matchingSection = availableSections.first(where: { $0.name.lowercased() == categoryLower }) {
                sectionId = matchingSection.id
            } else {
                return fallbackClassification(text, availableSections: availableSections)
            }
        }
        
        // Low confidence goes to unsorted
        if validatedConfidence < 0.6 {
            sectionId = "unsorted"
        }
        
        return ClassificationResult(sectionId: sectionId, confidence: validatedConfidence)
    }
    
    func parseCommands(_ text: String, availableSections: [Section]) -> (cleanText: String, forcedCategory: String?, sectionName: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // Check for /task, /idea, /note commands
        if trimmed.hasPrefix("/task") || trimmed.lowercased().hasPrefix("/tasks") {
            let clean = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            return (clean, "tasks", nil)
        }
        
        if trimmed.hasPrefix("/idea") || trimmed.lowercased().hasPrefix("/ideas") {
            let clean = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            return (clean, "ideas", nil)
        }
        
        if trimmed.hasPrefix("/note") || trimmed.lowercased().hasPrefix("/notes") {
            let clean = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            return (clean, "notes", nil)
        }
        
        // Check for @SectionName content pattern
        if let atRange = trimmed.range(of: #"@(\w+)\s+(.+)"#, options: .regularExpression) {
            let match = String(trimmed[atRange])
            let parts = match.split(separator: " ", maxSplits: 1)
            if parts.count == 2 {
                let sectionName = String(parts[0].dropFirst()) // Remove @
                let content = String(parts[1])
                
                // Find matching section
                if let section = availableSections.first(where: { $0.name.lowercased() == sectionName.lowercased() }) {
                    return (content, section.id, sectionName)
                }
            }
        }
        
        return (trimmed, nil, nil)
    }
    
    private func extractJSON(from text: String) -> String {
        // Try to find JSON object in the text
        if let startRange = text.range(of: "{"),
           let endRange = text.range(of: "}", options: .backwards) {
            return String(text[startRange.lowerBound...endRange.upperBound])
        }
        return text
    }
    
    private func fallbackClassification(_ text: String, availableSections: [Section]) -> ClassificationResult {
        // Conservative fallback - default to unsorted
        let lower = text.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Very basic keyword matching as last resort
        let taskKeywords = ["get", "buy", "call", "email", "todo", "task", "do", "make"]
        let ideaKeywords = ["what if", "idea", "concept", "brainstorm", "imagine"]
        
        if taskKeywords.contains(where: { lower.contains($0) }) {
            return ClassificationResult(sectionId: "tasks", confidence: 0.5)
        }
        
        if ideaKeywords.contains(where: { lower.contains($0) }) {
            return ClassificationResult(sectionId: "ideas", confidence: 0.5)
        }
        
        return ClassificationResult(sectionId: "unsorted", confidence: 0.4)
    }
}

enum GroqError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}
