# Setup Instructions for Conotate macOS

## Creating the Xcode Project

1. **Open Xcode** and select "Create a new Xcode project"

2. **Choose Template**:
   - Select "macOS" tab
   - Choose "App"
   - Click "Next"

3. **Configure Project**:
   - Product Name: `ConotateMacOS`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: macOS 13.0
   - Click "Next" and choose a location

4. **Add Files**:
   - Delete the default `ContentView.swift` (we have our own)
   - Add all the Swift files from this directory to the project:
     - `ConotateMacOSApp.swift` (replace the default App file)
     - `AppState.swift`
     - `Models.swift`
     - `StorageManager.swift`
     - `Utils.swift`
     - `Constants.swift`
     - `Config.swift`
     - `GroqService.swift`
     - `ContentView.swift`
     - All files from the `Views/` folder

5. **Project Structure**:
   Your project should look like this:
   ```
   ConotateMacOS/
   ├── ConotateMacOSApp.swift
   ├── AppState.swift
   ├── Models.swift
   ├── StorageManager.swift
   ├── Utils.swift
   ├── Constants.swift
   ├── ContentView.swift
   └── Views/
       ├── TopBarView.swift
       ├── ComposerView.swift
       ├── HomeView.swift
       ├── LibraryView.swift
       ├── SectionPanelView.swift
       ├── SectionCardView.swift
       ├── NewSectionModalView.swift
       ├── SectionDetailModalView.swift
       ├── FlyingNoteView.swift
       └── TypewriterButton.swift
   ```

6. **Build Settings**:
   - Ensure "Swift Language Version" is set to Swift 5
   - Minimum macOS version: 13.0

7. **Configure Groq API Key**:
   You have two options to set the `GROQ_API_KEY`:
   
   **Option A: Using .env file (Recommended)**
   - Create a `.env` file in the project root directory (same level as your Xcode project)
   - Add: `GROQ_API_KEY=your_groq_api_key_here`
   - The app will automatically load it at runtime
   
   **Option B: Using Xcode Scheme Environment Variables**
   - In Xcode, go to Product → Scheme → Edit Scheme
   - Select "Run" in the left sidebar
   - Go to the "Arguments" tab
   - Under "Environment Variables", click "+"
   - Add: Name: `GROQ_API_KEY`, Value: `your_groq_api_key_here`
   - Click "Close"
   
   **Option C: System Environment Variable**
   - Set it in your shell: `export GROQ_API_KEY=your_groq_api_key_here`
   - Launch the app from Terminal: `open /path/to/ConotateMacOS.app`
   
   If no environment variable is set, the app will use a default key (hardcoded fallback).

8. **Run the App**:
   - Press `Cmd + R` to build and run
   - The app should launch with all features working

## Custom Fonts (Optional)

If you want to use the "Noto Serif" font family like the web version:

1. Download Noto Serif from Google Fonts
2. Add the font files to your project
3. Add them to `Info.plist` under "Fonts provided by application"
4. The app will automatically use them where `.custom("Noto Serif", size:)` is specified

If fonts aren't available, the system will fall back to the default serif font.

## Features Implemented

✅ All React components recreated in SwiftUI
✅ All animations (flying notes, carousel, transitions)
✅ Command system with `/` prefix
✅ Search and filtering
✅ Section management (create, edit, delete, bookmark)
✅ Note classification
✅ Dark mode support
✅ Data persistence
✅ Export/Import functionality
✅ Keyboard shortcuts
✅ Typewriter placeholder effect
✅ Settings mode
✅ All modals and overlays

## Known Differences from Web Version

- File system dialogs are native macOS (NSSavePanel) instead of browser downloads
- Some hover effects may feel slightly different due to macOS interaction patterns
- Keyboard shortcuts use Cmd instead of Ctrl on Mac

## Troubleshooting

**Build Errors:**
- Ensure all files are added to the target
- Check that Swift version is 5.7+
- Verify macOS deployment target is 13.0+

**Runtime Issues:**
- Check console for any errors
- Ensure UserDefaults permissions are available
- Verify all view dependencies are properly injected via `@EnvironmentObject`

**Visual Issues:**
- Custom fonts may need to be added (see above)
- Some colors use hex extensions - ensure `Color(hex:)` extension is working
- Check that all animations are using proper SwiftUI animation modifiers
