# Supabase Integration Setup Guide

## Overview

With Supabase integrated, **all data is saved to the cloud backend** (PostgreSQL database) instead of local storage. This enables:
- Multi-device sync
- Cloud backup
- Real-time updates
- Better scalability

## Step 1: Create Supabase Project

1. Go to https://supabase.com
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Name**: `Conotate` (or your choice)
   - **Database Password**: (save this securely)
   - **Region**: Choose closest to you
5. Click "Create new project"
6. Wait 2-3 minutes for project to be ready

## Step 2: Get Your Credentials

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public key** (starts with `eyJ...`)

## Step 3: Add Credentials to Xcode

1. Open Xcode
2. Go to **Product** → **Scheme** → **Edit Scheme...**
3. Select **Run** → **Arguments** tab
4. Under **Environment Variables**, add:
   - **Name**: `SUPABASE_URL`
   - **Value**: Your project URL
5. Add another:
   - **Name**: `SUPABASE_ANON_KEY`
   - **Value**: Your anon public key
6. Click **Close**

## Step 4: Add Supabase Swift Package

1. In Xcode, select your project in the navigator
2. Select your target (`Conotate_v2`)
3. Go to **Package Dependencies** tab
4. Click **+** button
5. Enter: `https://github.com/supabase/supabase-swift`
6. Click **Add Package**
7. Select **Supabase** (not SupabaseStorage or others)
8. Click **Add Package**

## Step 5: Create Database Tables

Run this SQL in your Supabase SQL Editor (Dashboard → SQL Editor):

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Sections table
CREATE TABLE IF NOT EXISTS sections (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    emoji TEXT,
    tags TEXT[],
    description TEXT,
    is_bookmarked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notes table
CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    section_id TEXT NOT NULL,
    text TEXT NOT NULL,
    tags TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sections_user_id ON sections(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_section_id ON notes(section_id);

-- Enable Row Level Security (RLS)
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Create policies so users can only access their own data
CREATE POLICY "Users can view their own sections"
    ON sections FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own sections"
    ON sections FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own sections"
    ON sections FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own sections"
    ON sections FOR DELETE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can view their own notes"
    ON notes FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own notes"
    ON notes FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own notes"
    ON notes FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own notes"
    ON notes FOR DELETE
    USING (auth.uid()::text = user_id);
```

## Step 6: Update Authentication Settings

1. In Supabase Dashboard, go to **Authentication** → **Settings**
2. Under **Site URL**, add your app's URL (for development: `http://localhost`)
3. Under **Redirect URLs**, add: `http://localhost`
4. Save changes

## Step 7: Test the Integration

1. Build and run your app
2. Try logging in (will use Supabase Auth)
3. Create a note
4. Check Supabase Dashboard → **Table Editor** → **notes** to see your data in the cloud!

## Migration from Local Storage

When you first log in with Supabase:
- Your existing local data will remain in UserDefaults
- New entries will be saved to Supabase
- You can optionally migrate existing data (see migration guide)

## Troubleshooting

**Error: "Supabase not configured"**
- Check that `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set in Xcode scheme

**Error: "Authentication failed"**
- Verify your Supabase project is active
- Check that email/password auth is enabled in Supabase Dashboard

**Error: "Table doesn't exist"**
- Run the SQL script from Step 5 in Supabase SQL Editor

**Data not syncing**
- Check internet connection
- Verify RLS policies are set correctly
- Check Supabase Dashboard logs for errors
