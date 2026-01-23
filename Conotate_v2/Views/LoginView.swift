//
//  LoginView.swift
//  ConotateMacOS
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var apiKey: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showAPIKeyField: Bool = false
    @State private var needsAPIKeyForAccount: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
        case apiKey
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                appState.themeColor
                    .ignoresSafeArea()
                
                // Dots pattern background
                DotsPatternView()
                    .ignoresSafeArea()
                
                // Login Card
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 32) {
                        // App Title
                        VStack(spacing: 8) {
                            Text("Conotate")
                                .font(.system(size: 48, weight: .semibold, design: .serif))
                                .foregroundColor(.black.opacity(0.85))
                                .tracking(-1)
                            
                            Text("Sign in to continue")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .padding(.bottom, 8)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 12, weight: .medium, design: .default))
                                    .foregroundColor(.black.opacity(0.7))
                                
                                TextField("", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundColor(.black.opacity(0.85))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(focusedField == .email ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                    .focused($focusedField, equals: .email)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 12, weight: .medium, design: .default))
                                    .foregroundColor(.black.opacity(0.7))
                                
                                SecureField("", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundColor(.black.opacity(0.85))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(focusedField == .password ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                    .focused($focusedField, equals: .password)
                                    .onSubmit {
                                        if showAPIKeyField {
                                            focusedField = .apiKey
                                        } else {
                                            handleLogin()
                                        }
                                    }
                            }
                            
                            // API Key Field (shown if account needs it)
                            if showAPIKeyField || needsAPIKeyForAccount {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Groq API Key")
                                            .font(.system(size: 12, weight: .medium, design: .default))
                                            .foregroundColor(.black.opacity(0.7))
                                        
                                        Spacer()
                                        
                                        Text("(Optional)")
                                            .font(.system(size: 11, weight: .regular, design: .default))
                                            .foregroundColor(.gray.opacity(0.6))
                                    }
                                    
                                    SecureField("Enter your API key", text: $apiKey)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                                        .foregroundColor(.black.opacity(0.85))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(focusedField == .apiKey ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                        .focused($focusedField, equals: .apiKey)
                                        .onSubmit {
                                            handleLogin()
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
                            }
                            
                            // Error Message
                            if showError {
                                Text(errorMessage)
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                    .foregroundColor(.red.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, -8)
                            }
                            
                            // Login/Sign Up Buttons
                            HStack(spacing: 12) {
                                TypewriterButton(variant: .primary) {
                                    handleLogin()
                                } label: {
                                    Text("Sign In")
                                        .font(.system(size: 14, weight: .semibold, design: .default))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                
                                TypewriterButton(variant: .secondary) {
                                    handleSignUp()
                                } label: {
                                    Text("Sign Up")
                                        .font(.system(size: 14, weight: .semibold, design: .default))
                                        .foregroundColor(.black.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .frame(width: 400)
                    }
                    .padding(48)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 8)
                    )
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .onAppear {
            // Check if there's a pending email that needs API key
            if let pendingEmail = StorageManager.shared.loadString(key: "pending-api-key-email"),
               !pendingEmail.isEmpty {
                email = pendingEmail
                needsAPIKeyForAccount = true
                showAPIKeyField = true
                // Clear the pending email flag
                StorageManager.shared.saveString(key: "pending-api-key-email", value: "")
            }
        }
    }
    
    private func handleLogin() {
        // Clear previous error
        showError = false
        errorMessage = ""
        
        // Validate inputs
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true
            errorMessage = "Please enter your email"
            return
        }
        
        guard !password.isEmpty else {
            showError = true
            errorMessage = "Please enter your password"
            return
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        // Check if account needs API key (before login attempt)
        let normalizedUserId = trimmedEmail.lowercased()
            .replacingOccurrences(of: "@", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        
        let savedKey = StorageManager.shared.loadString(key: "groq-api-key", userId: normalizedUserId)
        let hasAPIKey = savedKey != nil && !(savedKey?.isEmpty ?? true)
        
        // If account doesn't have API key and user hasn't entered one, show the field
        if !hasAPIKey && apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            showAPIKeyField = true
            needsAPIKeyForAccount = true
            // Don't proceed with login yet, let them enter API key
            return
        }
        
        // Attempt login with Supabase Auth
        Task {
            do {
                try await appState.login(email: trimmedEmail, password: password)
                
                // Login successful - save API key if provided
                if !apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
                    appState.saveAPIKey(apiKey.trimmingCharacters(in: .whitespaces))
                }
                
                // Clear form on main thread
                await MainActor.run {
                    email = ""
                    password = ""
                    apiKey = ""
                    showAPIKeyField = false
                    needsAPIKeyForAccount = false
                    showError = false
                }
            } catch {
                // Login failed
                await MainActor.run {
                    showError = true
                    if let loginError = error as? AppState.LoginError {
                        errorMessage = loginError.errorDescription ?? "Login failed"
                    } else {
                        errorMessage = "Invalid email or password"
                    }
                    password = "" // Clear password on error
                }
            }
        }
    }
    
    private func handleSignUp() {
        // Clear previous error
        showError = false
        errorMessage = ""
        
        // Validate inputs
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true
            errorMessage = "Please enter your email"
            return
        }
        
        guard !password.isEmpty else {
            showError = true
            errorMessage = "Please enter your password"
            return
        }
        
        guard password.count >= 6 else {
            showError = true
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        // Attempt sign up with Supabase Auth
        Task {
            do {
                try await appState.signUp(email: trimmedEmail, password: password)
                
                // Sign up successful - save API key if provided
                if !apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
                    appState.saveAPIKey(apiKey.trimmingCharacters(in: .whitespaces))
                }
                
                // Clear form on main thread
                await MainActor.run {
                    email = ""
                    password = ""
                    apiKey = ""
                    showAPIKeyField = false
                    needsAPIKeyForAccount = false
                    showError = false
                }
            } catch {
                // Sign up failed
                await MainActor.run {
                    showError = true
                    if let loginError = error as? AppState.LoginError {
                        errorMessage = loginError.errorDescription ?? "Sign up failed"
                    } else {
                        errorMessage = "Sign up failed. Email may already be in use."
                    }
                    password = "" // Clear password on error
                }
            }
        }
    }
}
