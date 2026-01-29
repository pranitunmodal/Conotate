# Frontend

This directory contains the SwiftUI macOS application for Conotate.

## Structure

```
frontend/
├── Conotate_v2/              # Main app directory
│   ├── Views/                # SwiftUI views
│   │   ├── SimpleComposerView.swift
│   │   ├── HomeView.swift
│   │   ├── CollapsibleSectionListView.swift
│   │   └── [other views]
│   ├── Services/             # Frontend services
│   │   └── GroqService.swift # HTTP client for Edge Functions
│   ├── AppState.swift        # State management
│   ├── Models.swift          # Data models (Section, Note)
│   ├── Utils.swift           # Utility functions
│   ├── Config.swift          # Configuration loader
│   ├── Constants.swift       # App constants
│   ├── ContentView.swift     # Root view
│   └── ConotateMacOSApp.swift # App entry point
├── Conotate_v2.xcodeproj/    # Xcode project
└── Assets.xcassets/          # App assets
```

## Views

### Core Views
- **SimpleComposerView** - Unified input for search/add with mode switching (Cmd+S/Cmd+E)
- **HomeView** - Main app view with composer and collapsible sections
- **CollapsibleSectionListView** - Expandable sections with notes and dates
- **LoginView** - Authentication UI

### Supporting Views
- **TopBarView** - Top navigation bar with greeting and logout
- **LibraryView** - Search and filter interface
- **TypewriterButton** - Custom button component

## Services

### GroqService
HTTP client for calling Supabase Edge Functions:
- `classifyNote(_:availableSections:)` - Calls `classify-note` Edge Function
- `generateDescription(for:sectionName:)` - Calls `generate-description` Edge Function

## State Management

### AppState
Central state management using `ObservableObject`:
- Authentication state (`isAuthenticated`, `currentUserEmail`)
- Data state (`sections`, `notes`)
- UI state (`currentView`, `searchQuery`, `expandedSectionId`)
- Methods for data operations (`addNote`, `createNewSection`, etc.)

## Models

- **Section** - Represents a note section/category
- **Note** - Represents an individual note entry
- **ViewState**, **ScreenView** - UI state enums

## Integration with Backend

The frontend accesses backend services through:
- `HybridStorageManager.shared` - Data persistence (from `backend/services/`)
- `SupabaseService.shared` - Supabase client (from `backend/services/`)
- `GroqService.shared` - Edge Function HTTP client

## Building

Open `Conotate_v2.xcodeproj` in Xcode and build. The backend services are included in the Xcode project and compiled with the frontend.

## Environment Variables

Set these in Xcode scheme or `.env` file:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anonymous key

## Features

- **Dual Mode Input**: Entry mode (Cmd+E) and Search mode (Cmd+S)
- **AI Classification**: Automatic note categorization via Edge Functions
- **Collapsible Sections**: Expandable section list with date-sorted notes
- **Hybrid Storage**: Supabase cloud storage with local fallback
- **Authentication**: Supabase Auth integration
