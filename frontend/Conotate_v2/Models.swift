//
//  Models.swift
//  ConotateMacOS
//

import Foundation

struct Section: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var emoji: String?
    var createdAt: TimeInterval
    var updatedAt: TimeInterval
    var tags: [String]?
    var description: String?
    var isBookmarked: Bool?
    
    init(id: String = UUID().uuidString, 
         name: String, 
         emoji: String? = nil,
         createdAt: TimeInterval = Date().timeIntervalSince1970,
         updatedAt: TimeInterval = Date().timeIntervalSince1970,
         tags: [String]? = nil,
         description: String? = nil,
         isBookmarked: Bool = false) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.description = description
        self.isBookmarked = isBookmarked
    }
}

struct Note: Identifiable, Codable, Equatable {
    let id: String
    var text: String
    var sectionId: String
    var createdAt: TimeInterval
    var updatedAt: TimeInterval
    var tags: [String]?
    
    init(id: String = UUID().uuidString,
         text: String,
         sectionId: String,
         createdAt: TimeInterval = Date().timeIntervalSince1970,
         updatedAt: TimeInterval = Date().timeIntervalSince1970,
         tags: [String]? = nil) {
        self.id = id
        self.text = text
        self.sectionId = sectionId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
    }
}

struct Connector: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var createdAt: TimeInterval
    
    init(id: String = UUID().uuidString,
         name: String,
         createdAt: TimeInterval = Date().timeIntervalSince1970) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

enum ViewState {
    case collapsed
    case expanded
}

enum ScreenView {
    case home
    case library
    case profile
    case settings
}

enum FilterGroup1 {
    case recent
    case bookmarked
    case all
}

enum FilterGroup2 {
    case grid
    case bento
    case tree
}

extension Section {
    struct PartialSection {
        var name: String?
        var tags: [String]?
        var description: String?
    }
}
