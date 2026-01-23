//
//  Config.swift
//  ConotateMacOS
//
//  Helper to load environment variables from .env file
//

import Foundation

class Config {
    static let shared = Config()
    
    private var env: [String: String] = [:]
    
    private init() {
        loadEnvFile()
    }
    
    private func loadEnvFile() {
        let fileManager = FileManager.default
        let userName = NSUserName()
        
        // Priority order: Check most likely locations first
        let possiblePaths: [String] = [
            // 1. Explicit project path (most reliable for development)
            "/Users/\(userName)/Desktop/conotate_v2.0/.env",
            // 2. Current working directory (when running from terminal)
            fileManager.currentDirectoryPath + "/.env",
            // 3. Go up from executable to find project root (for Xcode builds)
            {
                if let executablePath = Bundle.main.executablePath {
                    var currentPath = (executablePath as NSString).deletingLastPathComponent
                    for _ in 0..<10 {
                        let envPath = (currentPath as NSString).appendingPathComponent(".env")
                        if fileManager.fileExists(atPath: envPath) {
                            return envPath
                        }
                        let parentPath = (currentPath as NSString).deletingLastPathComponent
                        if parentPath == currentPath { break }
                        currentPath = parentPath
                    }
                }
                return nil
            }(),
            // 4. Home directory
            NSHomeDirectory() + "/.env",
            // 5. App bundle resources (for production builds)
            Bundle.main.resourcePath.map { ($0 as NSString).appendingPathComponent(".env") },
            // 6. App bundle path
            (Bundle.main.bundlePath as NSString).appendingPathComponent(".env"),
            // 7. Parent of bundle path
            ((Bundle.main.bundlePath as NSString).deletingLastPathComponent as NSString).appendingPathComponent(".env")
        ].compactMap { $0 }
        
        // Try each path in order
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                    parseEnvFile(content)
                    print("✅ Loaded .env file from: \(path)")
                    return
                }
            }
        }
        
        // Debug: Print that .env wasn't found
        print("⚠️ .env file not found. Checked paths:")
        for path in possiblePaths {
            let exists = fileManager.fileExists(atPath: path)
            print("   - \(path) \(exists ? "✅ EXISTS" : "❌")")
        }
        print("💡 Tip: Make sure .env file exists at: /Users/\(userName)/Desktop/conotate_v2.0/.env")
    }
    
    private func parseEnvFile(_ content: String) {
        print("📖 Parsing .env file content...")
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                env[key] = value
                print("   ✅ Loaded: \(key) = \(String(repeating: "*", count: min(value.count, 10)))...")
            }
        }
        print("📋 Total keys loaded: \(env.keys.count)")
    }
    
    func get(_ key: String, userId: String? = nil) -> String? {
        // First check system environment
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            print("📦 Found \(key) in system environment")
            return value
        }
        
        // Then check user-specific storage (for API keys)
        if key == "GROQ_API_KEY", let userId = userId {
            let normalizedUserId = userId.lowercased()
                .replacingOccurrences(of: "@", with: "-")
                .replacingOccurrences(of: ".", with: "-")
            
            if let userKey = StorageManager.shared.loadString(key: "groq-api-key", userId: normalizedUserId), !userKey.isEmpty {
                print("👤 Found \(key) in user storage for: \(userId)")
                return userKey
            }
        }
        
        // Then check .env file
        if let value = env[key], !value.isEmpty {
            print("📄 Found \(key) in .env file")
            return value
        }
        
        print("⚠️ \(key) not found in system env, user storage, or .env file")
        if let userId = userId {
            print("   Checked user: \(userId)")
        }
        return nil
    }
}
