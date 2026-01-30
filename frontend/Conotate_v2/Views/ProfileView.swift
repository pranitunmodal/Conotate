//
//  ProfileView.swift
//  ConotateMacOS
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            
            HStack(spacing: 16) {
                Text(appState.userAvatar)
                    .font(.system(size: 40))
                    .frame(width: 64, height: 64)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.userName)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                    if let email = appState.currentUserEmail {
                        Text(email)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var header: some View {
        HStack {
            Text("Profile")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
            
            TypewriterButton(variant: .secondary) {
                appState.currentView = .home
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10))
                    Text("Back")
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }
    }
}
