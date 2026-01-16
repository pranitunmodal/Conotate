//
//  FlyingNoteView.swift
//  ConotateMacOS
//

import SwiftUI

struct FlyingNoteView: View {
    @EnvironmentObject var appState: AppState
    let note: FlyingNoteState
    
    @State private var startPosition: CGPoint = .zero
    @State private var targetPosition: CGPoint = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            Text(note.text)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(.gray.opacity(0.8))
                .lineLimit(2)
                .padding(20)
                .frame(width: min(geometry.size.width * 0.3, 300))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 40, x: 0, y: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .position(targetPosition)
                .opacity(opacity)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    // Calculate start position (from composer)
                    startPosition = CGPoint(
                        x: geometry.size.width / 2,
                        y: 200
                    )
                    
                    // Calculate target position (to section card)
                    if appState.sections.contains(where: { $0.id == note.targetSectionId }) {
                        // Approximate position - in real app would get actual card position
                        targetPosition = CGPoint(
                            x: geometry.size.width / 2,
                            y: geometry.size.height - 300
                        )
                    } else {
                        targetPosition = CGPoint(
                            x: geometry.size.width / 2,
                            y: geometry.size.height
                        )
                    }
                    
                    // Animate
                    withAnimation(.easeInOut(duration: 2.0)) {
                        opacity = 0
                        scale = 0.2
                        rotation = Double.random(in: -10...10)
                    }
                }
        }
    }
}
