# Conotate macOS

A beautiful note-taking and organization app for macOS, built with SwiftUI.

<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

## Features

- **Smart Note Classification**: Automatically categorizes notes into Tasks, Ideas, or Notes based on keywords
- **AI-Powered Descriptions**: Uses Groq API to generate intelligent section descriptions
- **Section Management**: Create, organize, bookmark, and delete sections
- **Search & Filter**: Full-text search across all notes and sections with filtering options
- **Command System**: Type `/` to access commands (settings, search, create section, etc.)
- **Beautiful Animations**: Smooth transitions, flying note animations, and interactive carousels
- **Dark Mode**: Full dark mode support with customizable theme colors
- **Data Persistence**: All data stored locally using UserDefaults
- **Export/Import**: Export your data as JSON or export individual sections as text files

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Setup

See [ConotateMacOS/SETUP.md](ConotateMacOS/SETUP.md) for detailed setup instructions.

Quick start:
1. Open the project in Xcode
2. Add all Swift files from `ConotateMacOS/` to your Xcode project
3. Build and run (Cmd + R)

## Keyboard Shortcuts

- `Cmd + Enter`: Save note
- `Cmd + Shift + Enter`: Open search
- `/`: Open command menu
- `ESC`: Close modals/views
- Arrow keys: Navigate command menu

## Project Structure

```
ConotateMacOS/
├── ConotateMacOSApp.swift      # App entry point
├── AppState.swift               # Main state management
├── Models.swift                 # Data models (Section, Note)
├── StorageManager.swift         # Data persistence
├── Utils.swift                  # Utility functions
├── Constants.swift              # Default data and constants
├── GroqService.swift           # Groq API integration
├── ContentView.swift             # Main view container
└── Views/
    ├── TopBarView.swift         # Top navigation bar
    ├── ComposerView.swift       # Main text input component
    ├── HomeView.swift           # Home screen
    ├── LibraryView.swift        # Library/search view
    ├── SectionPanelView.swift  # Bottom section carousel
    ├── SectionCardView.swift    # Individual section card
    ├── NewSectionModalView.swift # Create section modal
    ├── SectionDetailModalView.swift # Section detail modal
    ├── FlyingNoteView.swift     # Flying note animation
    └── TypewriterButton.swift   # Custom button component
```

## Groq API

The app uses Groq API for AI-powered features. The API key is configured in `GroqService.swift`. The service provides:
- Intelligent section description generation
- Enhanced note classification (optional)

All API calls have graceful fallbacks to keyword-based methods if the API is unavailable.
