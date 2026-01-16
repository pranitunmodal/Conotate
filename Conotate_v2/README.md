# Conotate macOS

A beautiful note-taking and organization app for macOS, recreated from the React/TypeScript web version with full feature parity and 1:1 visual matching.

## Features

- **Smart Note Classification**: Automatically categorizes notes into Tasks, Ideas, or Notes based on keywords
- **Section Management**: Create, organize, bookmark, and delete sections
- **Search & Filter**: Full-text search across all notes and sections with filtering options
- **Command System**: Type `/` to access commands (settings, search, create section, etc.)
- **Beautiful Animations**: Smooth transitions, flying note animations, and interactive carousels
- **Dark Mode**: Full dark mode support with customizable theme colors
- **Data Persistence**: All data stored locally using UserDefaults
- **Export/Import**: Export your data as JSON or export individual sections as text files

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
├── ContentView.swift             # Main view container
└── Views/
    ├── TopBarView.swift         # Top navigation bar
    ├── ComposerView.swift       # Main text input component
    ├── HomeView.swift           # Home screen
    ├── LibraryView.swift        # Library/search view
    ├── SectionPanelView.swift   # Bottom section carousel
    ├── SectionCardView.swift    # Individual section card
    ├── NewSectionModalView.swift # Create section modal
    ├── SectionDetailModalView.swift # Section detail modal
    ├── FlyingNoteView.swift     # Flying note animation
    └── TypewriterButton.swift   # Custom button component
```

## Building

1. Open the project in Xcode
2. Select your target (macOS 13.0+)
3. Build and run (Cmd + R)

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Notes

- All animations use SwiftUI's native animation system
- Data is persisted using UserDefaults (can be migrated to Core Data if needed)
- The app maintains visual 1:1 parity with the React version
- All components are fully functional with the same interactions
