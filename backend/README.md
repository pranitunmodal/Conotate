# Backend

This directory contains all backend-related code for Conotate, including Supabase services and Edge Functions.

## Structure

```
backend/
├── services/          # Swift services for data layer and Supabase integration
│   ├── SupabaseService.swift      # Supabase client wrapper (auth, database)
│   ├── HybridStorageManager.swift  # Data persistence layer (Supabase + local fallback)
│   └── StorageManager.swift        # Local storage fallback (UserDefaults)
└── edge-functions/   # Supabase Edge Functions (TypeScript/Deno)
    ├── classify-note/              # AI note classification
    ├── generate-description/        # AI section description generation
    └── groq-proxy/                 # Legacy Groq proxy (deprecated)
```

## Services

### SupabaseService
- Handles authentication (sign in, sign up, sign out, session management)
- Database operations (CRUD for sections and notes)
- Edge Function authentication helpers

### HybridStorageManager
- Abstraction layer for data persistence
- Uses Supabase when configured, falls back to local storage
- Provides unified API for frontend

### StorageManager
- Local storage implementation using UserDefaults
- Used as fallback when Supabase is not configured
- Per-user data isolation

## Edge Functions

Supabase Edge Functions are serverless TypeScript functions deployed to Supabase.

### Deploying Edge Functions

```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy classify-note
supabase functions deploy generate-description
```

### Development

Edge Functions are located in `backend/edge-functions/`. Each function has its own directory with an `index.ts` file.

**Note:** The Supabase CLI expects functions in `supabase/functions/` by default. You may need to configure the CLI or use a symlink if your deployment process requires it.

### Environment Variables

Edge Functions access secrets via Supabase:
- `GROQ_API_KEY` - Stored as Supabase secret
- `SUPABASE_URL` - Automatically injected
- `SUPABASE_ANON_KEY` - Automatically injected

## Integration with Frontend

Backend services are Swift files that are compiled with the frontend app. They're organized here for logical separation but are part of the same Xcode project.

The frontend accesses backend services through:
- `SupabaseService.shared`
- `HybridStorageManager.shared`
- `StorageManager.shared`

## API Reference

### Authentication
- `signIn(email:password:)` - Sign in user
- `signUp(email:password:)` - Create new user
- `signOut()` - Sign out current user
- `getCurrentUserId()` - Get current user ID
- `getAccessToken()` - Get current session token

### Data Operations
- `createSection(_:userId:)` - Create new section
- `fetchSections(userId:)` - Get all sections for user
- `updateSection(id:updates:userId:)` - Update section
- `deleteSection(id:userId:)` - Delete section
- `createNote(_:userId:)` - Create new note
- `fetchNotes(userId:)` - Get all notes for user
- `updateNote(id:text:userId:)` - Update note
- `deleteNote(id:userId:)` - Delete note
