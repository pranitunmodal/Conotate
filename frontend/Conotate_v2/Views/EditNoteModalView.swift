//
//  EditNoteModalView.swift
//  ConotateMacOS
//

import SwiftUI

struct EditNoteModalView: View {
    @EnvironmentObject var appState: AppState
    @State private var editedText = ""
    @State private var selectedSectionId = ""
    @State private var showDeleteConfirm = false
    
    var note: Note? {
        guard let id = appState.editingNoteId else { return nil }
        return appState.notes.first { $0.id == id }
    }
    
    private var modalBackground: Color {
        appState.isDarkMode ? Color(hex: "#1A1A1A") : Color(hex: "#FEFDFB")
    }
    
    private var modalBorderColor: Color {
        appState.isDarkMode ? Color.white.opacity(0.12) : Color(hex: "#E5E2D6")
    }
    
    private var fieldBackground: Color {
        appState.isDarkMode ? Color.white.opacity(0.08) : Color.white
    }
    
    private var fieldBorderColor: Color {
        appState.isDarkMode ? Color.white.opacity(0.15) : Color(hex: "#A6A6A6")
    }
    
    private var textColor: Color {
        appState.isDarkMode ? Color.white.opacity(0.9) : Color.primary
    }
    
    private var secondaryTextColor: Color {
        appState.isDarkMode ? Color.white.opacity(0.6) : Color.gray.opacity(0.7)
    }
    
    var body: some View {
        if let note = note {
            ZStack {
                Color.black.opacity(appState.isDarkMode ? 0.5 : 0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            appState.editingNoteId = nil
                        }
                    }
                
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Edit Note")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                appState.editingNoteId = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryTextColor)
                            
                            TextEditor(text: $editedText)
                                .font(.system(size: 14))
                                .foregroundColor(textColor)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80, maxHeight: 200)
                                .padding(12)
                                .background(fieldBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(fieldBorderColor, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Section")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryTextColor)
                            
                            Picker("", selection: $selectedSectionId) {
                                ForEach(appState.sections) { section in
                                    Text(section.name).tag(section.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(fieldBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(fieldBorderColor, lineWidth: 1)
                            )
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                Text("Delete")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Cancel") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                appState.editingNoteId = nil
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        
                        Button("Save") {
                            let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                appState.updateNote(id: note.id, text: trimmed)
                            }
                            if selectedSectionId != note.sectionId {
                                appState.updateNoteSection(id: note.id, sectionId: selectedSectionId)
                            }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                appState.editingNoteId = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(32)
                .frame(width: 480)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(modalBackground)
                        .shadow(color: .black.opacity(appState.isDarkMode ? 0.4 : 0.12), radius: 13, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(modalBorderColor, lineWidth: 1)
                        )
                )
                .onAppear {
                    editedText = note.text
                    selectedSectionId = note.sectionId
                }
                .alert("Delete Note?", isPresented: $showDeleteConfirm) {
                    Button("Cancel", role: .cancel) {
                        showDeleteConfirm = false
                    }
                    Button("Delete", role: .destructive) {
                        appState.deleteNote(id: note.id)
                        showDeleteConfirm = false
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            appState.editingNoteId = nil
                        }
                    }
                } message: {
                    Text("This note will be permanently deleted.")
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.92)),
                removal: .opacity.combined(with: .scale(scale: 0.96))
            ))
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: appState.editingNoteId != nil)
        }
    }
}
