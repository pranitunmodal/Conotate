//
//  SectionPanelView.swift
//  ConotateMacOS
//

import SwiftUI

struct SectionPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeIndex = 0
    
    var body: some View {
        VStack {
            if appState.bottomPanelView == .collapsed {
                collapsedView
            } else {
                expandedView
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appState.bottomPanelView)
    }
    
    var collapsedView: some View {
        TypewriterButton(variant: .secondary) {
            withAnimation {
                appState.bottomPanelView = .expanded
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10))
                Text("SECTIONS")
                    .font(.system(size: 10, weight: .bold, design: .default))
                    .foregroundColor(.gray.opacity(0.6))
                    .tracking(2)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 9)
        }
        .padding(.bottom, 32)
    }
    
    var expandedView: some View {
        VStack(spacing: 0) {
            // Control Bar
            HStack {
                Spacer()
                HStack(spacing: 16) {
                    TypewriterButton(variant: .secondary) {
                        appState.currentView = .library
                    } label: {
                        Text("See All")
                            .font(.system(size: 10, weight: .bold, design: .default))
                            .foregroundColor(.gray.opacity(0.7))
                            .tracking(2)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 9)
                    }
                    
                    TypewriterButton(variant: .secondary) {
                        withAnimation {
                            appState.bottomPanelView = .collapsed
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .frame(width: 40, height: 40)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 40)
            
            // Carousel
            HStack(spacing: 128) {
                // Previous Button
                TypewriterButton(variant: .secondary) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        activeIndex = (activeIndex - 1 + appState.sections.count) % appState.sections.count
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .frame(width: 40, height: 40)
                }
                
                // Carousel Container
                ZStack {
                    ForEach(Array(appState.sections.enumerated()), id: \.element.id) { index, section in
                        SectionCardView(
                            section: section,
                            notes: appState.notes.filter { $0.sectionId == section.id },
                            variant: .carousel,
                            index: index,
                            activeIndex: activeIndex,
                            shouldPulse: appState.pulseSectionId == section.id,
                            onDelete: { exportFirst in
                                appState.deleteSection(id: section.id, exportFirst: exportFirst)
                            },
                            onToggleBookmark: {
                                appState.toggleBookmark(id: section.id)
                            },
                            onClick: {
                                if index == activeIndex {
                                    appState.expandedSectionId = section.id
                                } else {
                                    withAnimation {
                                        activeIndex = index
                                    }
                                }
                            }
                        )
                        .environmentObject(appState)
                        .offset(x: CGFloat(index - activeIndex) * 55)
                        .scaleEffect(1.0 - abs(CGFloat(index - activeIndex)) * 0.1)
                        .opacity(1.0 - abs(CGFloat(index - activeIndex)) * 0.2)
                        .zIndex(Double(100 - abs(index - activeIndex)))
                    }
                }
                .frame(width: 240, height: 200)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold {
                                withAnimation {
                                    activeIndex = (activeIndex - 1 + appState.sections.count) % appState.sections.count
                                }
                            } else if value.translation.width < -threshold {
                                withAnimation {
                                    activeIndex = (activeIndex + 1) % appState.sections.count
                                }
                            }
                        }
                )
                
                // Next Button
                TypewriterButton(variant: .secondary) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        activeIndex = (activeIndex + 1) % appState.sections.count
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.bottom, 40)
    }
}
