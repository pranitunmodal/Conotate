//
//  Config.swift
//  ConotateMacOS
//
//  Helper to load environment variables from .env file
//
//  Environment Variable Loading Priority:
//  1. System environment variables (from Xcode scheme: Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables)
//  2. App bundle resources (.env file added to Xcode project as a resource)
//  3. File system paths (project root, home directory, etc.)
//
//  To add .env file to Xcode project:
//  - Right-click on Conotate_v2 folder in Xcode
//  - Select "Add Files to Conotate_v2..."
//  - Navigate to project root and select .env file
//  - Check "Copy items if needed" and "Add to targets: Conotate_v2"
//  - Ensure it's added to the Resources build phase
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
        
        // Priority order: Check bundle resources first (most reliable for Xcode builds)
        // Then check file system paths
        var possiblePaths: [String] = []
        
        // 1. App bundle resources (highest priority for Xcode builds)
        if let resourcePath = Bundle.main.resourcePath {
            possiblePaths.append((resourcePath as NSString).appendingPathComponent(".env"))
        }
        
        // 2. Explicit project path (reliable for development)
        possiblePaths.append("/Users/\(userName)/Desktop/conotate_v2.0/.env")
        
        // 3. Current working directory (when running from terminal)
        possiblePaths.append(fileManager.currentDirectoryPath + "/.env")
        
        // 4. Go up from executable to find project root (for Xcode builds)
        if let executablePath = Bundle.main.executablePath {
            var currentPath = (executablePath as NSString).deletingLastPathComponent
            for _ in 0..<10 {
                let envPath = (currentPath as NSString).appendingPathComponent(".env")
                if !possiblePaths.contains(envPath) {
                    possiblePaths.append(envPath)
                }
                let parentPath = (currentPath as NSString).deletingLastPathComponent
                if parentPath == currentPath { break }
                currentPath = parentPath
            }
        }
        
        // 5. Home directory
        possiblePaths.append(NSHomeDirectory() + "/.env")
        
        // 6. App bundle path
        possiblePaths.append((Bundle.main.bundlePath as NSString).appendingPathComponent(".env"))
        
        // 7. Parent of bundle path
        possiblePaths.append(((Bundle.main.bundlePath as NSString).deletingLastPathComponent as NSString).appendingPathComponent(".env"))
        
        // Try each path in order
        var lastError: Error?
        var checkedPaths: [(path: String, exists: Bool, error: String?)] = []
        
        for path in possiblePaths {
            let exists = fileManager.fileExists(atPath: path)
            var errorMessage: String? = nil
            
            if exists {
                do {
                    let content = try String(contentsOfFile: path, encoding: .utf8)
                    if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        parseEnvFile(content)
                        print("✅ Loaded .env file from: \(path)")
                        return
                    } else {
                        errorMessage = "File is empty"
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    lastError = error
                    print("   ⚠️ Failed to read \(path): \(error.localizedDescription)")
                }
            }
            
            checkedPaths.append((path: path, exists: exists, error: errorMessage))
        }
        
        // Debug: Print detailed information about all checked paths
        print("⚠️ .env file not found or could not be loaded. Checked paths:")
        for checked in checkedPaths {
            if checked.exists {
                if let error = checked.error {
                    print("   - \(checked.path) ✅ EXISTS but ❌ ERROR: \(error)")
                } else {
                    print("   - \(checked.path) ✅ EXISTS")
                }
            } else {
                print("   - \(checked.path) ❌ NOT FOUND")
            }
        }
        
        if let error = lastError {
            print("   Last error: \(error.localizedDescription)")
        }
        
        print("💡 Tips:")
        print("   1. Make sure .env file exists at: /Users/\(userName)/Desktop/conotate_v2.0/.env")
        print("   2. Add .env file to Xcode project as a resource (File > Add Files to Project)")
        print("   3. Or set environment variables in Xcode scheme (Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables)")
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
                var value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                
                // Remove quotes if present (both single and double)
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) || 
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }
                
                env[key] = value
                print("   ✅ Loaded: \(key) = \(String(repeating: "*", count: min(value.count, 10)))...")
            } else {
                print("   ⚠️ Skipping malformed line: \(trimmed.prefix(50))")
            }
        }
        print("📋 Total keys loaded: \(env.keys.count)")
        if !env.isEmpty {
            print("   Keys: \(Array(env.keys).joined(separator: ", "))")
        }
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
        if !env.isEmpty {
            print("   Available .env keys: \(Array(env.keys).joined(separator: ", "))")
        }
        if let userId = userId {
            print("   Checked user: \(userId)")
        }
        return nil
    }
}
