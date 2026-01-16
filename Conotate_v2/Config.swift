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
        // Try to load from .env file in the app bundle or working directory
        let possiblePaths = [
            Bundle.main.resourcePath?.appending("/.env"),
            Bundle.main.bundlePath.appending("/.env"),
            FileManager.default.currentDirectoryPath.appending("/.env"),
            NSHomeDirectory().appending("/.env"),
            "/Users/\(NSUserName())/Desktop/conotate_v2.0/.env"
        ]
        
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                    parseEnvFile(content)
                    break
                }
            }
        }
    }
    
    private func parseEnvFile(_ content: String) {
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
            }
        }
    }
    
    func get(_ key: String) -> String? {
        // First check system environment
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value
        }
        // Then check .env file
        return env[key]
    }
}
