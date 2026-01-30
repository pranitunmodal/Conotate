//
//  SectionCardView.swift
//  ConotateMacOS
//

import SwiftUI

struct SectionCardView: View {
    @EnvironmentObject var appState: AppState
    let section: Section
    let notes: [Note]
    var variant: CardVariant = .grid
    var index: Int = 0
    var activeIndex: Int = 0
    var shouldPulse: Bool = false
    var highlightQuery: String? = nil
    var onDelete: ((Bool) -> Void)? = nil
    var onToggleBookmark: (() -> Void)? = nil
    var onClick: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var isMenuOpen = false
    @State private var showDeleteConfirm = false
    @State private var exportChecked = false
    
    enum CardVariant {
        case grid
        case carousel
    }
    
    var sectionNotes: [Note] {
        notes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var displayNotes: [Note] {
        if let query = highlightQuery, !query.isEmpty {
            let q = query.lowercased()
            return sectionNotes.filter { $0.text.lowercased().contains(q) }
        }
        return Array(sectionNotes.prefix(3))
    }
    
    var isActive: Bool {
        variant == .carousel ? (index == activeIndex) : true
    }
    
    var isOpen: Bool {
        if let query = highlightQuery, !query.isEmpty {
            return true
        }
        return isHovered && isActive && !isMenuOpen && !showDeleteConfirm
    }
    
    var body: some View {
        ZStack {
            cardContent
                .frame(width: variant == .carousel ? 240 : nil, height: 200)
                .scaleEffect(shouldPulse ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: shouldPulse)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if !showDeleteConfirm {
                onClick?()
            }
        }
        .id("section-card-\(section.id)")
    }
    
    var cardContent: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#E5E2D6").opacity(0.5), lineWidth: 1)
                )
            
            // Noise Texture (removed for cleaner look)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header with Actions
                if isActive && !showDeleteConfirm {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            // Bookmark Button
                            Button(action: {
                                onToggleBookmark?()
                            }) {
                                Image(systemName: section.isBookmarked ?? false ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(section.isBookmarked ?? false ? .yellow : .gray.opacity(0.4))
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.5))
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // Menu Button
                            Menu {
                                Button(role: .destructive, action: {
                                    isMenuOpen = false
                                    showDeleteConfirm = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.4))
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.5))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    Text(section.name)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(1)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    
                    // Tags (hidden when open)
                    if !isOpen {
                        if let tags = section.tags, !tags.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(Array(tags.prefix(3)), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11, weight: .regular, design: .default))
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Description or Notes
                    ZStack(alignment: .topLeading) {
                        // Description (default)
                        if !isOpen {
                            Text(section.description ?? "No description available.")
                                .font(.system(size: 11, weight: .regular, design: .default))
                                .foregroundColor(.gray.opacity(0.7))
                                .lineSpacing(2)
                                .lineLimit(4)
                                .padding(.horizontal, 24)
                                .padding(.top, 6)
                        }
                        
                        // Notes (on hover/search)
                        if isOpen {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(highlightQuery != nil ? "MATCHES" : "LATEST")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(.gray.opacity(0.4))
                                    .padding(.horizontal, 24)
                                
                                if !displayNotes.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(displayNotes) { note in
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("•")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.gray.opacity(0.3))
                                                highlightedText(note.text, query: highlightQuery)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.gray.opacity(0.6))
                                                    .lineLimit(2)
                                            }
                                            .padding(.horizontal, 24)
                                            .contentShape(Rectangle())
                                            .onTapGesture(count: 2) {
                                                appState.editingNoteId = note.id
                                            }
                                        }
                                    }
                                } else {
                                    Text(highlightQuery != nil ? "No matching notes." : "No notes yet.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray.opacity(0.3))
                                        .italic()
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Footer (hidden when open)
                    if !isOpen {
                        HStack {
                            Text("\(sectionNotes.count) NOTES")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.gray.opacity(0.5))
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.15))
                                .offset(y: -8),
                            alignment: .top
                        )
                    }
                }
                .padding(.bottom, 24)
            }
            
            // Delete Confirmation Modal
            if showDeleteConfirm {
                deleteConfirmationOverlay
            }
        }
    }
    
    var deleteConfirmationOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            
            VStack(spacing: 16) {
                Text("Delete \"\(section.name)\"?")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray.opacity(0.8))
                
                Toggle("Export as PDF", isOn: $exportChecked)
                    .font(.system(size: 10))
                    .toggleStyle(.checkbox)
                
                HStack(spacing: 8) {
                    Button("Cancel") {
                        showDeleteConfirm = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Delete") {
                        onDelete?(exportChecked)
                        showDeleteConfirm = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.red)
                }
            }
            .padding(20)
        }
    }
    
    @ViewBuilder
    func highlightedText(_ text: String, query: String?) -> some View {
        if let query = query, !query.isEmpty {
            let parts = text.components(separatedBy: query)
            if parts.count > 1 {
                // Multiple parts - build with highlighting
                HStack(spacing: 0) {
                    ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                        if index > 0 {
                            Text(query)
                                .background(Color.yellow.opacity(0.5))
                        }
                        Text(part)
                    }
                }
            } else {
                Text(text)
            }
        } else {
            Text(text)
        }
    }
}

// Noise Texture View
struct NoiseTextureView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Simple noise pattern using random dots
                for _ in 0..<1000 {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let opacity = Double.random(in: 0.1...0.3)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.black.opacity(opacity))
                    )
                }
            }
        }
    }
}
