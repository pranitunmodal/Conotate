//
//  SectionDetailModalView.swift
//  ConotateMacOS
//

import SwiftUI

struct SectionDetailModalView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedTags = ""
    
    var section: Section? {
        guard let id = appState.expandedSectionId else { return nil }
        return appState.sections.first { $0.id == id }
    }
    
    var notes: [Note] {
        guard let id = appState.expandedSectionId else { return [] }
        return appState.notes.filter { $0.sectionId == id }
    }
    
    var groupedNotes: [String: [Note]] {
        Utils.groupNotesByDate(notes)
    }
    
    var body: some View {
        if let section = section, appState.expandedSectionId != nil {
            modalContent(section: section)
        }
    }
    
    @ViewBuilder
    private func modalContent(section: Section) -> some View {
        ZStack {
            backdrop
            
            VStack(spacing: 0) {
                headerView(section: section)
                scrollableContent(section: section)
                footerView(section: section)
            }
            .frame(width: 768)
            .frame(maxHeight: 720)
            .background(modalBackground)
            .onAppear {
                editedName = section.name
                editedTags = section.tags?.joined(separator: " ") ?? ""
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.expandedSectionId != nil)
    }
    
    private var backdrop: some View {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation {
                    appState.expandedSectionId = nil
                }
            }
    }
    
    @ViewBuilder
    private func headerView(section: Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isEditing {
                    TextField("", text: $editedName)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .fontWeight(.semibold)
                        .textFieldStyle(.plain)
                } else {
                    Text(section.name)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                closeButton
            }
            
            if isEditing {
                TextField("#tag1 #tag2", text: $editedTags)
                    .font(.system(size: 11, weight: .medium))
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.2))
                            .offset(y: -2),
                        alignment: .bottom
                    )
            } else {
                Text(section.tags?.joined(separator: "  |  ") ?? "#untagged")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray.opacity(0.5))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    private var closeButton: some View {
        Button(action: {
            withAnimation {
                appState.expandedSectionId = nil
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.4))
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func scrollableContent(section: Section) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                aiDescriptionView(section: section)
                notesListView
                
                if notes.isEmpty {
                    Text("No notes yet. Add some from the home screen!")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.3))
                        .italic()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
    
    @ViewBuilder
    private func aiDescriptionView(section: Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.4))
                Text("AI GENERATED")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.gray.opacity(0.4))
            }
            
            Text(section.description ?? Utils.generateDescription(notes: notes, sectionName: section.name))
                .task {
                    if section.description == nil || section.description?.isEmpty == true {
                        let newDescription = await Utils.generateDescriptionWithGroq(notes: notes, sectionName: section.name)
                        if let sectionId = appState.expandedSectionId,
                           let index = appState.sections.firstIndex(where: { $0.id == sectionId }) {
                            appState.sections[index].description = newDescription
                            appState.saveData()
                        }
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(24)
        .background(descriptionBackground)
    }
    
    private var descriptionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#F3F2EA"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E8E6DC"), lineWidth: 1)
            )
    }
    
    @ViewBuilder
    private var notesListView: some View {
        ForEach(Array(groupedNotes.keys.sorted()), id: \.self) { dateLabel in
            dateGroupView(dateLabel: dateLabel)
        }
    }
    
    @ViewBuilder
    private func dateGroupView(dateLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateLabel.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.leading, 4)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.1))
                        .offset(y: 8),
                    alignment: .bottom
                )
            
            ForEach(groupedNotes[dateLabel] ?? []) { note in
                noteRowView(note: note)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        appState.editingNoteId = note.id
                    }
            }
        }
    }
    
    @ViewBuilder
    private func noteRowView(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.3))
                
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: Binding(
                            get: { note.text },
                            set: { newValue in
                                appState.updateNote(id: note.id, text: newValue)
                            }
                        ))
                        .frame(height: 40)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Section selector for classification
                        HStack(spacing: 8) {
                            Text("Section:")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Picker("", selection: Binding(
                                get: { note.sectionId },
                                set: { newSectionId in
                                    appState.updateNoteSection(id: note.id, sectionId: newSectionId)
                                }
                            )) {
                                ForEach(appState.sections) { section in
                                    Text(section.name).tag(section.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                    }
                } else {
                    HStack {
                        Text(note.text)
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.7))
                            .lineSpacing(4)
                        
                        Spacer()

                        Button {
                            appState.deleteNote(id: note.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        
                        Text(timeString(from: note.updatedAt))
                            .font(.system(size: 9))
                            .foregroundColor(.gray.opacity(0.4))
                            .opacity(0)
                    }
                }
            }
        }
        .padding(.leading, 4)
    }
    
    @ViewBuilder
    private func footerView(section: Section) -> some View {
        HStack {
            Spacer()
            if isEditing {
                editModeButtons(section: section)
            } else {
                viewModeButton
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(footerBackground)
    }
    
    @ViewBuilder
    private func editModeButtons(section: Section) -> some View {
        TypewriterButton(variant: .ghost) {
            isEditing = false
        } label: {
            Text("Cancel")
                .font(.system(size: 12, weight: .medium))
        }
        
        TypewriterButton(variant: .dark) {
            let newTags = editedTags.split(separator: " ").filter { $0.hasPrefix("#") }.map { String($0) }
            let newDescription = Utils.generateDescription(notes: notes, sectionName: editedName)
            var updates = Section.PartialSection()
            updates.name = editedName
            updates.tags = newTags
            updates.description = newDescription
            appState.updateSection(id: section.id, updates: updates)
            isEditing = false
        } label: {
            HStack(spacing: 4) {
                Text("Save Changes")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var viewModeButton: some View {
        TypewriterButton(variant: .secondary) {
            isEditing = true
        } label: {
            HStack(spacing: 4) {
                Text("Edit")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "pencil")
                    .font(.system(size: 10))
            }
        }
    }
    
    private var footerBackground: some View {
        Rectangle()
            .fill(Color.white.opacity(0.5))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.1))
                    .offset(y: -1),
                alignment: .top
            )
    }
    
    private var modalBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#FEFDFB"))
                .shadow(color: .black.opacity(0.12), radius: 13, x: 0, y: 10)
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "#E5E2D6"), lineWidth: 1)
            
            NoiseTextureView()
                .opacity(0.15)
                .blendMode(.multiply)
        }
    }
    
    func timeString(from timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
