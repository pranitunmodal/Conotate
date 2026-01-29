//
//  LibraryView.swift
//  ConotateMacOS
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var filterGroup1: FilterGroup1 = .all
    @State private var filterGroup2: FilterGroup2 = .grid
    @State private var inputValue = ""
    @State private var activeQuery = ""
    
    var filteredSections: [Section] {
        var result = appState.sections
        
        // Filter by Group 1
        switch filterGroup1 {
        case .bookmarked:
            result = result.filter { $0.isBookmarked ?? false }
        case .recent:
            // TODO: Implement recently viewed tracking
            break
        case .all:
            break
        }
        
        // Text search filtering
        if !activeQuery.isEmpty {
            let q = activeQuery.lowercased()
            result = result.filter { section in
                section.name.lowercased().contains(q) ||
                appState.notes.contains { note in
                    note.sectionId == section.id && note.text.lowercased().contains(q)
                }
            }
        }
        
        return result
    }
    
    var isSearching: Bool {
        !activeQuery.isEmpty && activeQuery == inputValue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Header with Search and Add buttons
            HStack {
                Spacer()
                HStack(spacing: 12) {
                    TypewriterButton(variant: .secondary) {
                        // Search functionality - could focus the composer or trigger search
                        // For now, just ensure we're in library view
                    } label: {
                        HStack(spacing: 4) {
                            Text("Search")
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                        }
                    }
                    
                    TypewriterButton(variant: .primary) {
                        // Switch to home view to add a note
                        appState.currentView = .home
                    } label: {
                        HStack(spacing: 4) {
                            Text("Add")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Top Composer Bar
            ComposerView(
                variant: .bar,
                autoFocus: true,
                initialText: appState.pendingSearchQuery,
                showClassificationPreview: !isSearching
            ) { newValue in
                inputValue = newValue
                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    activeQuery = ""
                }
            }
            .environmentObject(appState)
            .onChange(of: inputValue) { oldValue, newValue in
                // Auto-search as user types
                activeQuery = newValue
            }
            
            // Content Area
            ScrollView {
                VStack(spacing: 0) {
                    // Filters Row
                    HStack {
                        // Group 1: Recent / Bookmarked / All
                        HStack(spacing: 0) {
                            FilterButton(title: "Recently Viewed", isActive: filterGroup1 == .recent) {
                                filterGroup1 = .recent
                            }
                            FilterButton(title: "Bookmarked", isActive: filterGroup1 == .bookmarked) {
                                filterGroup1 = .bookmarked
                            }
                            FilterButton(title: "All", isActive: filterGroup1 == .all) {
                                filterGroup1 = .all
                            }
                        }
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(999)
                        
                        // Group 2: Grid / Bento / Tree
                        HStack(spacing: 0) {
                            FilterButton(title: "Grid View", isActive: filterGroup2 == .grid, isEnabled: true) {
                                filterGroup2 = .grid
                            }
                            FilterButton(title: "Bento View", isActive: filterGroup2 == .bento, isEnabled: false) {
                                filterGroup2 = .bento
                            }
                            FilterButton(title: "Tree View", isActive: filterGroup2 == .tree, isEnabled: false) {
                                filterGroup2 = .tree
                            }
                        }
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(999)
                        
                        Spacer()
                        
                        TypewriterButton(variant: .ghost) {
                            appState.isNewSectionModalOpen = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Create New Section")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                                Image(systemName: "plus")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    
                    // Section Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ], spacing: 24) {
                        ForEach(filteredSections) { section in
                            SectionCardView(
                                section: section,
                                notes: appState.notes.filter { $0.sectionId == section.id },
                                variant: .grid,
                                highlightQuery: activeQuery.isEmpty ? nil : activeQuery,
                                onDelete: { exportFirst in
                                    appState.deleteSection(id: section.id, exportFirst: exportFirst)
                                },
                                onToggleBookmark: {
                                    appState.toggleBookmark(id: section.id)
                                },
                                onClick: {
                                    appState.expandedSectionId = section.id
                                }
                            )
                            .environmentObject(appState)
                        }
                    }
                    .frame(maxWidth: 1200)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                    
                    if filteredSections.isEmpty {
                        Text(activeQuery.isEmpty ? (filterGroup1 == .bookmarked ? "No bookmarked sections." : "No sections found.") : "No matches found.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.4))
                            .italic()
                            .padding(.vertical, 80)
                    }
                }
            }
            
            // Floating Bottom Center "See Less" Button
            VStack {
                Spacer()
                TypewriterButton(variant: .secondary) {
                    withAnimation {
                        appState.currentView = .home
                        appState.pendingSearchQuery = ""
                    }
                } label: {
                    Text("SEE LESS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            inputValue = appState.pendingSearchQuery
            activeQuery = appState.pendingSearchQuery
        }
        .onKeyPress(.escape, action: {
            if !activeQuery.isEmpty {
                activeQuery = ""
                inputValue = ""
            } else {
                appState.currentView = .home
            }
            return .handled
        })
    }
}

struct FilterButton: View {
    let title: String
    let isActive: Bool
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isActive ? .gray.opacity(0.8) : (isEnabled ? .gray.opacity(0.5) : .gray.opacity(0.3)))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                        .background(
                    isActive ? Color(hex: "#E8E6DC").opacity(0.6) : Color.clear
                )
                .cornerRadius(999)
                .shadow(color: isActive ? .black.opacity(0.08) : .clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
