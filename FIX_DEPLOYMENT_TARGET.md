# Fix: Minimum Deployment Target

## Issue
Your project has Minimum Deployment set to **macOS 15.7**, but the app is designed for **macOS 13.0**.

## Fix Steps

1. In Xcode, select your project in the navigator (top item: "Conotate_v2")
2. Select the **"Conotate_v2"** target (under TARGETS)
3. Go to the **"General"** tab (which you're already on)
4. Find **"Minimum Deployments"** section
5. Change **"macOS"** from `15.7` to `13.0`
6. Press Enter or click elsewhere to save

## Why This Matters

- macOS 15.7 doesn't exist yet (current latest is macOS 15.x Sequoia)
- Setting it too high prevents the app from running on older macOS versions
- The app code uses features available in macOS 13.0+
- This might also be causing build/run issues

## After Changing

1. Clean build folder: **Product → Clean Build Folder** (Shift + Cmd + K)
2. Try building again: **Cmd + B**
3. Then run: **Cmd + R**

---

**Note**: The indexing will continue in the background. You can still build/run while it's indexing, though autocomplete might be limited until it finishes.
