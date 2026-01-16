# Distribution Guide - Sharing Conotate with Your Team

This guide will walk you through sharing your macOS app with your team using TestFlight (Apple's beta testing platform).

## Prerequisites
- ✅ Apple Developer Account (you have this)
- ✅ Xcode installed
- ✅ App Store Connect access

## Step 1: Configure Your App in Xcode

### 1.1 Update Bundle Identifier
1. Open your project in Xcode
2. Select the project in the navigator (top item)
3. Select the **Conotate_v2** target
4. Go to **Signing & Capabilities** tab
5. Update **Bundle Identifier** to something like: `com.yourcompany.conotate` or `com.yourname.conotate`
   - This must be unique and match what you'll register in App Store Connect
   - Current value: `Blank.Conotate-v2` (needs to be changed)

### 1.2 Configure Signing
1. In the same **Signing & Capabilities** tab:
   - Check **"Automatically manage signing"**
   - Select your **Team** (your Apple Developer account)
   - Xcode will automatically create provisioning profiles

### 1.3 Update Version Numbers
1. Still in the target settings, go to **General** tab:
   - **Version**: `1.0` (or increment as needed)
   - **Build**: `1` (increment this for each build you upload)

### 1.4 Disable App Sandbox (if needed)
Your app uses file system access. Check if App Sandbox is enabled:
1. Go to **Signing & Capabilities** tab
2. If you see "App Sandbox", you may need to:
   - Either disable it (for testing)
   - Or configure proper entitlements (for App Store submission)

## Step 2: Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Click **"My Apps"** → **"+"** → **"New App"**
4. Fill in the details:
   - **Platform**: macOS
   - **Name**: Conotate (or your preferred name)
   - **Primary Language**: English
   - **Bundle ID**: Select the one you created (or create new)
   - **SKU**: A unique identifier (e.g., `conotate-macos-001`)
   - **User Access**: Full Access (for team testing)
5. Click **"Create"**

## Step 3: Archive and Upload Your App

### 3.1 Clean and Archive
1. In Xcode, select **"Any Mac"** as the destination (top toolbar)
2. Select **Product** → **Clean Build Folder** (Shift+Cmd+K)
3. Select **Product** → **Archive** (this may take a few minutes)
4. The Organizer window will open automatically

### 3.2 Upload to App Store Connect
1. In the Organizer window, select your archive
2. Click **"Distribute App"**
3. Choose **"App Store Connect"**
4. Click **"Next"**
5. Choose **"Upload"** (not Export)
6. Click **"Next"**
7. Select your distribution options:
   - ✅ **"Upload your app's symbols"** (recommended for crash reports)
   - ✅ **"Manage Version and Build Number"** (if you want Xcode to manage it)
8. Click **"Next"**
9. Review and click **"Upload"**
10. Wait for the upload to complete (this may take 10-30 minutes)

## Step 4: Set Up TestFlight

### 4.1 Wait for Processing
- After upload, Apple needs to process your build (usually 10-60 minutes)
- You'll get an email when it's ready
- Check App Store Connect → TestFlight tab for status

### 4.2 Add Internal Testers (Fastest - No Review)
1. In App Store Connect, go to your app
2. Click **"TestFlight"** tab
3. Go to **"Internal Testing"** section
4. Click **"+"** to add internal testers
5. Add team members by email (they must be added to your App Store Connect team first)
6. Select the build you uploaded
7. Click **"Start Testing"**

**Note**: Internal testers can test immediately (up to 100 people, must be in your App Store Connect team)

### 4.3 Add External Testers (Requires Beta Review)
1. Go to **"External Testing"** section
2. Click **"+"** to create a new group
3. Name it (e.g., "Beta Testers")
4. Add testers by email (up to 10,000)
5. Fill in **"What to Test"** information
6. Submit for Beta App Review (usually 24-48 hours)
7. Once approved, testers can install via TestFlight app

## Step 5: Testers Install the App

Your team members need to:
1. Install **TestFlight** app from the Mac App Store (if not already installed)
2. Accept the email invitation from Apple
3. Open TestFlight app
4. Click **"Install"** next to your app
5. The app will install and they can start testing!

## Alternative: Direct Distribution (Ad Hoc)

If you want to skip TestFlight and distribute directly:

### Option A: Export for Distribution
1. Archive your app (same as Step 3.1)
2. In Organizer, click **"Distribute App"**
3. Choose **"Ad Hoc"** or **"Developer ID"**
4. Export and share the `.app` file or create a `.dmg`

**Note**: This requires manual distribution and testers may need to allow the app in System Settings → Privacy & Security

## Troubleshooting

### "No accounts with App Store Connect access"
- Make sure you're signed in with the correct Apple ID in Xcode
- Go to Xcode → Settings → Accounts → Add your Apple Developer account

### "Bundle identifier is already in use"
- Choose a different bundle identifier
- Or use the existing app if it's yours

### "Upload failed" or signing errors
- Make sure your Apple Developer account is selected in Signing & Capabilities
- Try cleaning the build folder and archiving again
- Check that your bundle identifier matches App Store Connect

### Build processing takes too long
- This is normal, Apple processes builds on their servers
- Usually takes 10-60 minutes, sometimes longer during peak times

## Quick Checklist

- [ ] Updated Bundle Identifier in Xcode
- [ ] Configured signing with your team
- [ ] Created app in App Store Connect
- [ ] Archived the app in Xcode
- [ ] Uploaded to App Store Connect
- [ ] Waited for processing to complete
- [ ] Added internal/external testers
- [ ] Testers received invitations and installed TestFlight

## Need Help?

- [Apple's TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Xcode Distribution Guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
