//
//  TypewriterButton.swift
//  ConotateMacOS
//

import SwiftUI

struct TypewriterButton<Label: View>: View {
    let variant: ButtonVariant
    let action: () -> Void
    let label: () -> Label
    
    enum ButtonVariant {
        case primary
        case secondary
        case ghost
        case dark
    }
    
    init(variant: ButtonVariant = .primary, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.variant = variant
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: action) {
            label()
                .padding(.horizontal, variant == .ghost ? 12 : 20)
                .padding(.vertical, variant == .ghost ? 6 : 10)
                .background(backgroundView)
                .overlay(overlayView)
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .onHover { hovering in
            // Hover effects handled by background
        }
    }
    
    @ViewBuilder
    var backgroundView: some View {
        switch variant {
        case .primary, .dark:
            RoundedRectangle(cornerRadius: 999)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        case .secondary:
            RoundedRectangle(cornerRadius: 999)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.8), Color.white.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        case .ghost:
            Color.clear
        }
    }
    
    @ViewBuilder
    var overlayView: some View {
        switch variant {
        case .primary, .dark:
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        case .secondary:
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        case .ghost:
            EmptyView()
        }
    }
    
    var shadowColor: Color {
        switch variant {
        case .primary, .dark:
            return Color.black.opacity(0.12)
        case .secondary:
            return Color.black.opacity(0.04)
        case .ghost:
            return Color.clear
        }
    }
    
    var shadowRadius: CGFloat {
        switch variant {
        case .primary, .dark:
            return 12
        case .secondary:
            return 12
        case .ghost:
            return 0
        }
    }
    
    var shadowY: CGFloat {
        switch variant {
        case .primary, .dark:
            return 4
        case .secondary:
            return 4
        case .ghost:
            return 0
        }
    }
}

extension TypewriterButton where Label == Text {
    init(_ title: String, variant: ButtonVariant = .primary, action: @escaping () -> Void) {
        self.variant = variant
        self.action = action
        self.label = { Text(title) }
    }
}
