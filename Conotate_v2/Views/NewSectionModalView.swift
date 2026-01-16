//
//  NewSectionModalView.swift
//  ConotateMacOS
//

import SwiftUI

struct NewSectionModalView: View {
    @EnvironmentObject var appState: AppState
    @State private var title = ""
    @State private var tags = ""
    @State private var content = ""
    
    var body: some View {
        if appState.isNewSectionModalOpen {
            ZStack {
                // Backdrop
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            appState.isNewSectionModalOpen = false
                        }
                    }
                
                // Modal Content
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text("Create New Section")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                appState.isNewSectionModalOpen = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Form
                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title*")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.7))
                            
                            TextField("Give your section a title", text: $title)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#A6A6A6"), lineWidth: 1)
                                )
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags*")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.7))
                            
                            TextField("Add tags", text: $tags)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#A6A6A6"), lineWidth: 1)
                                )
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.7))
                            
                            TextEditor(text: $content)
                                .frame(height: 128)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#A6A6A6"), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Actions
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            TypewriterButton(variant: .ghost) {
                                withAnimation {
                                    appState.isNewSectionModalOpen = false
                                }
                            } label: {
                                Text("Discard")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            
                            TypewriterButton(variant: .primary) {
                                let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                                appState.createNewSection(title: title, tags: tagList, content: content)
                                withAnimation {
                                    appState.isNewSectionModalOpen = false
                                }
                                title = ""
                                tags = ""
                                content = ""
                            } label: {
                                Text("Create")
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(minWidth: 120)
                            }
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .padding(32)
                .frame(width: 512)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "#FEFDFB"))
                        .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "#E8E6DC"), lineWidth: 1)
                )
                .onTapGesture {
                    // Prevent closing when clicking inside
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.isNewSectionModalOpen)
            .onAppear {
                content = appState.pendingContent
            }
        }
    }
}
