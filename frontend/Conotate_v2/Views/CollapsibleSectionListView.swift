//
//  CollapsibleSectionListView.swift
//  ConotateMacOS
//

import SwiftUI

struct CollapsibleSectionListView: View {
    @EnvironmentObject var appState: AppState
    
    var filteredSections: [Section] {
        let sections = appState.sections
        
        // If searching, filter sections that have matching notes
        if !appState.searchQuery.isEmpty {
            let query = appState.searchQuery.lowercased()
            return sections.filter { section in
                let sectionNotes = appState.notes.filter { $0.sectionId == section.id }
                return section.name.lowercased().contains(query) ||
                       sectionNotes.contains { $0.text.lowercased().contains(query) }
            }
        }
        
        return sections
    }
    
    var sortedSections: [Section] {
        // Sort sections by most recent entry date
        return filteredSections.sorted { section1, section2 in
            let notes1 = appState.notes.filter { $0.sectionId == section1.id }
            let notes2 = appState.notes.filter { $0.sectionId == section2.id }
            
            let latest1 = notes1.map { $0.updatedAt }.max() ?? 0
            let latest2 = notes2.map { $0.updatedAt }.max() ?? 0
            
            return latest1 > latest2
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sortedSections) { section in
                    SectionRowView(section: section)
                        .environmentObject(appState)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(appState.themeColor)
    }
}

struct SectionRowView: View {
    @EnvironmentObject var appState: AppState
    let section: Section
    
    var isExpanded: Bool {
        appState.expandedSectionId == section.id
    }
    
    var sectionNotes: [Note] {
        let notes = appState.notes.filter { $0.sectionId == section.id }
        
        // Filter by search query if searching
        if !appState.searchQuery.isEmpty {
            let query = appState.searchQuery.lowercased()
            return notes.filter { $0.text.lowercased().contains(query) }
        }
        
        // Sort by most recent first
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button(action: {
                withAnimation {
                    if isExpanded {
                        appState.expandedSectionId = nil
                    } else {
                        appState.expandedSectionId = section.id
                    }
                }
            }) {
                HStack {
                    Text(isExpanded ? "▼" : ">")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray.opacity(0.6))
                        .frame(width: 20)
                    
                    Text(section.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
            }
            .buttonStyle(.plain)
            
            // Section notes (when expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(sectionNotes) { note in
                        NoteRowView(note: note)
                            .padding(.leading, 28)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color.white.opacity(0.3))
        .cornerRadius(6)
        .padding(.vertical, 4)
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("✓")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(Utils.formatDate(note.updatedAt))
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(note.text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
