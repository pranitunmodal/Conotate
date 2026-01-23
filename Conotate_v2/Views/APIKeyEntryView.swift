//
//  APIKeyEntryView.swift
//  ConotateMacOS
//

import SwiftUI

struct APIKeyEntryView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey: String = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't allow dismissing - API key is required
                }
            
            // Modal Card
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("API Key Required")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(.black.opacity(0.85))
                    
                    Text("To enable AI-powered features, please enter your Groq API key.\nThis will be saved securely to your account.")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 8)
                
                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Groq API Key")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.black.opacity(0.7))
                    
                    SecureField("Enter your API key", text: $apiKey)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(.black.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isFocused ? Color.blue.opacity(0.5) : Color.black.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .focused($isFocused)
                        .onSubmit {
                            handleSubmit()
                        }
                    
                    // Help text
                    HStack(spacing: 4) {
                        Text("Get your API key from")
                            .font(.system(size: 11, weight: .regular, design: .default))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Link("console.groq.com", destination: URL(string: "https://console.groq.com/")!)
                            .font(.system(size: 11, weight: .medium, design: .default))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, -4)
                }
                
                // Error Message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -8)
                }
                
                // Submit Button
                Button(action: {
                    handleSubmit()
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isSubmitting ? "Saving..." : "Save API Key")
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(apiKey.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.black.opacity(0.9))
                    )
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                .buttonStyle(.plain)
            }
            .padding(32)
            .frame(width: 480)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 32, x: 0, y: 8)
            )
        }
        .onAppear {
            // Auto-focus the input field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
    
    private func handleSubmit() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedKey.isEmpty else {
            showError = true
            errorMessage = "Please enter your API key"
            return
        }
        
        // Basic validation - Groq API keys typically start with "gsk_"
        guard trimmedKey.hasPrefix("gsk_") || trimmedKey.count > 20 else {
            showError = true
            errorMessage = "Please enter a valid Groq API key"
            return
        }
        
        isSubmitting = true
        showError = false
        
        // Save the API key
        appState.saveAPIKey(trimmedKey)
        
        // Small delay for UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSubmitting = false
            // The modal will close automatically when needsAPIKey becomes false
        }
    }
}
