//
//  Utils.swift
//  ConotateMacOS
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct Utils {
    static func classifyNote(_ text: String) -> String {
        let lower = text.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Enhanced task keywords - action verbs and shopping/reminder patterns
        let taskKeywords = [
            // Shopping/errands
            "get", "buy", "pick up", "grab", "purchase",
            // Action verbs
            "call", "email", "text", "message", "schedule", "finish", "complete", "submit", "pay", "review", "update", "fix", "create", "send", "meet", "attend", "do", "make", "prepare", "write", "read", "watch", "listen",
            // Reminders/imperatives
            "remember to", "don't forget", "need to", "should", "must", "have to", "todo", "task"
        ]
        
        // Enhanced idea keywords - creative thinking patterns
        let ideaKeywords = [
            "what if", "could we", "maybe we", "i wonder", "imagine", "consider", "app idea", "project concept", "feature idea", "brainstorm", "what if we", "should build", "could", "idea:", "concept:", "brainstorm"
        ]
        
        // Creative/conceptual patterns - detect imaginative or whimsical concepts
        // These are phrases that suggest creative ideas even without explicit keywords
        let creativePatterns = [
            "powered", "robot", "ai", "automatic", "smart", "flying", "magic", "invisible", "time travel", "teleport", "clone", "invention", "design", "concept", "prototype"
        ]
        
        // Check for task patterns first (more specific)
        if taskKeywords.contains(where: { lower.hasPrefix($0) || lower.contains(" \($0)") || lower.contains("\($0) ") }) {
            return "tasks"
        }
        
        // Check for idea keywords
        if ideaKeywords.contains(where: { lower.contains($0) }) {
            return "ideas"
        }
        
        // Check for creative/conceptual patterns (e.g., "cat powered laundry", "robot butler")
        // If it contains creative patterns and isn't clearly a task, it's likely an idea
        if creativePatterns.contains(where: { lower.contains($0) }) {
            // Make sure it's not a task (e.g., "fix the robot" would be a task)
            let isTask = taskKeywords.contains(where: { lower.contains($0) })
            if !isTask {
                return "ideas"
            }
        }
        
        // Default to unsorted - be conservative
        return "unsorted"
    }
    
    static func groupNotesByDate(_ notes: [Note]) -> [String: [Note]] {
        var groups: [String: [Note]] = [:]
        let sortedNotes = notes.sorted { $0.updatedAt > $1.updatedAt }
        
        for note in sortedNotes {
            let date = Date(timeIntervalSince1970: note.updatedAt)
            let now = Date()
            let diffTime = abs(now.timeIntervalSince(date))
            let diffDays = Int(ceil(diffTime / (60 * 60 * 24)))
            
            let key: String
            if diffDays <= 1 {
                key = "Today"
            } else if diffDays <= 2 {
                key = "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, d MMM yyyy"
                key = formatter.string(from: date)
            }
            
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(note)
        }
        
        return groups
    }
    
    static func generateDescription(notes: [Note], sectionName: String) -> String {
        if notes.isEmpty {
            return "This is the \(sectionName) section. Add notes to generate a summary."
        }
        // Fallback to simple description if Groq API is not available
        let keywords = notes.prefix(2).map { $0.text.split(separator: " ").prefix(3).joined(separator: " ") }.joined(separator: ", ")
        return "\(sectionName) currently focuses on \(keywords)... showing a mix of recent thoughts and tasks. The content suggests a productive workflow involving these topics."
    }
    
    static func generateDescriptionWithGroq(notes: [Note], sectionName: String) async -> String {
        do {
            return try await GroqService.shared.generateDescription(for: notes, sectionName: sectionName)
        } catch {
            // Fallback to simple description on error
            return generateDescription(notes: notes, sectionName: sectionName)
        }
    }
    
    static func classifyNoteWithGroq(_ text: String, availableSections: [Section]) async -> String {
        do {
            let result = try await GroqService.shared.classifyNote(text, availableSections: availableSections)
            return result.sectionId
        } catch {
            // Fallback to keyword-based classification
            return classifyNote(text)
        }
    }
    
    static func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yyyy"
        return formatter.string(from: date)
    }
    
    static func isColorDark(_ color: Color) -> Bool {
        let nsColor = NSColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luma < 0.4 // Threshold for dark
    }
    
    static func exportJSON(data: [String: Any], filename: String) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = filename
        savePanel.allowedContentTypes = [UTType.json]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? jsonString.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    static func exportSectionAsText(section: Section, notes: [Note]) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var content = "SECTION: \(section.name)\n"
        if let description = section.description {
            content += "\(description)\n"
        }
        content += "\nNOTES:\n"
        content += notes.map { note in
            let date = Date(timeIntervalSince1970: note.updatedAt)
            return "- \(note.text) (\(formatter.string(from: date)))"
        }.joined(separator: "\n")
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "\(section.name.replacingOccurrences(of: " ", with: "_"))_Export.txt"
        savePanel.allowedContentTypes = [UTType.plainText]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
