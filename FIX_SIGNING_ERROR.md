# Fix "No Team Found in Archive" Error

## What This Error Means

The archive you created doesn't have code signing configured with your Apple Developer team. This is required to distribute apps through TestFlight or the App Store.

## How to Fix It

### Step 1: Configure Signing in Xcode

1. **Open your project in Xcode**
2. **Select the project** in the navigator (the blue icon at the top)
3. **Select the "Conotate_v2" target** (under TARGETS in the main editor)
4. **Click the "Signing & Capabilities" tab**

### Step 2: Enable Automatic Signing

1. **Check the box** for **"Automatically manage signing"**
2. **Select your Team** from the dropdown:
   - If you see your Apple Developer account, select it
   - If you don't see it, click "Add Account..." and sign in with your Apple ID that has the Developer account

### Step 3: Update Bundle Identifier (if needed)

1. In the same **Signing & Capabilities** tab, check the **Bundle Identifier**
2. Currently it's: `Blank.Conotate-v2`
3. Change it to something like: `com.yourname.conotate` or `com.yourcompany.conotate`
   - This must be unique
   - Use reverse domain notation (e.g., `com.yourname.appname`)

### Step 4: Verify Signing

After selecting your team, you should see:
- ✅ **"Signing Certificate"** - Should show "Apple Development" or "Apple Distribution"
- ✅ **"Provisioning Profile"** - Should be automatically managed
- ✅ **Status** - Should show "Signing Certificate is valid"

### Step 5: Rebuild and Re-archive

1. **Clean the build folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Select "Any Mac"** as the destination (top toolbar)
3. **Archive again**: Product → Archive
4. Wait for the new archive to complete

### Step 6: Verify the New Archive

1. The Organizer window should open automatically
2. Select your new archive
3. Check the right sidebar - you should now see:
   - ✅ Your team name listed
   - ✅ Valid signing information
   - ✅ No errors

## Troubleshooting

### "No accounts available"
- Go to **Xcode → Settings → Accounts**
- Click **"+"** and add your Apple ID
- Make sure you're signed in with the account that has your Apple Developer membership

### "Bundle identifier is already in use"
- Choose a different bundle identifier
- Use your own domain/name (e.g., `com.yourname.conotate`)

### "Provisioning profile not found"
- Make sure **"Automatically manage signing"** is checked
- Xcode will create the provisioning profile automatically

### Still seeing the error after fixing?
- Delete the old archive (right-click → Delete)
- Make sure you're archiving with the **Release** configuration
- Try Product → Clean Build Folder, then archive again

## Quick Checklist

- [ ] Opened project in Xcode
- [ ] Selected project → target → "Signing & Capabilities" tab
- [ ] Checked "Automatically manage signing"
- [ ] Selected my Apple Developer team
- [ ] Updated bundle identifier (if needed)
- [ ] Cleaned build folder
- [ ] Created new archive
- [ ] Verified new archive shows team information

Once you see your team name in the archive details, you're ready to distribute!
