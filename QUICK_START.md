# Quick Start Guide - Creating Xcode Project

## The Problem
You opened the folder in Xcode, but there's no `.xcodeproj` file. Xcode needs a proper project to build and run.

## Solution: Create New Xcode Project

### Step 1: Create the Project
1. **Close the current Xcode window** (if you have the folder open)
2. **Open Xcode** and select **"Create a new Xcode project"** (or File → New → Project)
3. **Choose Template**:
   - Select **"macOS"** tab at the top
   - Choose **"App"**
   - Click **"Next"**

### Step 2: Configure Project
- **Product Name**: `ConotateMacOS`
- **Team**: (Select your team or leave None)
- **Organization Identifier**: `com.yourname` (or any identifier)
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None (we'll use UserDefaults)
- **Minimum Deployment**: **macOS 13.0**
- Click **"Next"**

### Step 3: Choose Location
- **Save location**: Choose `/Users/pranit/Desktop/conotate_v2.0/` 
- **IMPORTANT**: Uncheck "Create Git repository" (you already have one)
- Click **"Create"**

### Step 4: Replace Default Files
1. **Delete** the default `ContentView.swift` that Xcode created
2. **Delete** the default `ConotateMacOSApp.swift` (if it exists)

### Step 5: Add All Swift Files
1. In Xcode, right-click on the `ConotateMacOS` folder (or the project root)
2. Select **"Add Files to ConotateMacOS..."**
3. Navigate to `/Users/pranit/Desktop/conotate_v2.0/ConotateMacOS/`
4. **Select ALL Swift files**:
   - `ConotateMacOSApp.swift`
   - `AppState.swift`
   - `Models.swift`
   - `StorageManager.swift`
   - `Utils.swift`
   - `Constants.swift`
   - `Config.swift`
   - `GroqService.swift`
   - `ContentView.swift`
5. **Also add the `Views` folder** (select the entire folder)
6. Make sure **"Copy items if needed"** is **UNCHECKED** (files are already in the right place)
7. Make sure **"Add to targets: ConotateMacOS"** is **CHECKED**
8. Click **"Add"**

### Step 6: Verify Entry Point
1. Open `ConotateMacOSApp.swift`
2. Make sure it has `@main` annotation and looks correct
3. The file should start with:
   ```swift
   @main
   struct ConotateMacOSApp: App {
       @StateObject private var appState = AppState()
       ...
   ```

### Step 7: Build Settings Check
1. Click on the project name in the navigator (top item)
2. Select the **"ConotateMacOS"** target
3. Go to **"General"** tab
4. Verify **Minimum Deployments** is **macOS 13.0**
5. Go to **"Build Settings"** tab
6. Search for "Swift Language Version" - should be **Swift 5**

### Step 8: Set Environment Variable (Optional but Recommended)
1. In Xcode, go to **Product → Scheme → Edit Scheme...**
2. Select **"Run"** in the left sidebar
3. Go to **"Arguments"** tab
4. Under **"Environment Variables"**, click **"+"**
5. Add:
   - **Name**: `GROQ_API_KEY`
   - **Value**: `your_groq_api_key_here` (get your key from https://console.groq.com/)
6. Click **"Close"**

### Step 9: Build and Run!
1. Press **Cmd + B** to build (check for errors)
2. If build succeeds, press **Cmd + R** to run
3. The app should launch! 🎉

## Troubleshooting

**If Cmd+R still doesn't work:**
- Check the scheme selector (next to the stop button) - should say "ConotateMacOS > My Mac"
- Try Product → Run from the menu
- Check for build errors in the Issue Navigator (⌘5)

**If you see "No such module" errors:**
- Make sure all Swift files are added to the target
- Select each file and check "Target Membership" in the File Inspector (⌘⌥1)

**If the app crashes on launch:**
- Check the console for error messages
- Verify `ConotateMacOSApp.swift` has `@main` annotation
- Make sure `AppState` is properly initialized
