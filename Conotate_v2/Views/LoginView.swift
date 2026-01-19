//
//  LoginView.swift
//  ConotateMacOS
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
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
                                        handleLogin()
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
                            
                            // Login Button
                            TypewriterButton(variant: .primary) {
                                handleLogin()
                            } label: {
                                Text("Sign In")
                                    .font(.system(size: 14, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
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
        
        // Attempt login
        if appState.login(email: email.trimmingCharacters(in: .whitespaces), password: password) {
            // Login successful - authentication state will be updated in AppState
            showError = false
        } else {
            // Login failed
            showError = true
            errorMessage = "Invalid email or password"
            password = "" // Clear password on error
        }
    }
}
