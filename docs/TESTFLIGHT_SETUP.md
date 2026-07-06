# Agentbot TestFlight Setup Guide

## Prerequisites

1. **Apple Developer Account** ($99/year)
2. **Xcode 16+**
3. **App Store Connect API Key** (optional, for automated uploads)

## Step 1: Apple Developer Portal Setup

### Create App ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Click "+" → "App IDs"
3. Select "App" type
4. Description: "Agentbot"
5. Bundle ID: `sh.agentbot.app`
6. Enable capabilities:
   - Push Notifications
   - Associated Domains
   - App Groups: `group.sh.agentbot.app.shared`
7. Register

### Create Provisioning Profiles
1. Go to [Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Click "+" → "App Store" distribution profile
3. Select App ID: `sh.agentbot.app`
4. Select your distribution certificate
5. Name: `sh.agentbot.app AppStore`
6. Download and double-click to install

Repeat for:
- `sh.agentbot.app.share` (Share Extension)
- `sh.agentbot.app.activitywidget` (Activity Widget)
- `sh.agentbot.app.watchkitapp` (Watch App)

## Step 2: App Store Connect Setup

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+"
3. Enter:
   - Platform: iOS
   - Name: Agentbot
   - Primary Language: English
   - Bundle ID: `sh.agentbot.app`
   - SKU: `agentbot-ios`
   - User Access: Full Access
4. Create

## Step 3: Configure Signing in Xcode

1. Open `Agentbot.xcodeproj` in Xcode
2. Select the Agentbot target
3. Go to "Signing & Capabilities"
4. Change Team to your Apple Developer team
5. Repeat for all targets (ShareExtension, ActivityWidget, WatchApp)

## Step 4: Build for TestFlight

### Option A: Xcode (Recommended for first build)
1. In Xcode, select "Any iOS Device" as destination
2. Product → Archive
3. Wait for archive to complete
4. In Organizer, click "Distribute App"
5. Select "App Store Connect"
6. Upload

### Option B: Command Line
```bash
# Generate project
cd apps/ios && xcodegen generate && cd ../..

# Build archive
./scripts/build-testflight.sh

# Upload (requires App Store Connect API key)
APP_STORE_CONNECT_API_KEY=YOUR_KEY APP_STORE_CONNECT_ISSUER_ID=YOUR_ISSUER ./scripts/build-testflight.sh --upload
```

## Step 5: TestFlight Beta Testing

1. In App Store Connect, go to your app
2. Click "TestFlight" tab
3. Your uploaded build will appear (processing takes 10-30 minutes)
4. Add internal testers:
   - Click "Internal Testing" → "+" to create a group
   - Add testers by email
5. Add external testers:
   - Click "External Testing" → "+" to create a group
   - Add testers by email or create a public link

## Step 6: Version Management

Update version in `apps/ios/version.json`:
```json
{
  "version": "2026.7.2"
}
```

Then sync:
```bash
cd apps/ios && xcodegen generate
```

## Troubleshooting

### "No matching provisioning profiles found"
- Ensure you've created and downloaded the provisioning profile
- Double-click the `.mobileprovision` file to install
- In Xcode, try "Download Manual Profiles"

### "Archive failed"
- Check that all targets have valid signing
- Verify bundle IDs match App Store Connect

### "Upload failed"
- Ensure App Store Connect app exists
- Check that the bundle ID matches
- Verify your distribution certificate is valid

## Environment Variables (Optional)

For automated uploads, set these:
```bash
export APP_STORE_CONNECT_API_KEY="YOUR_API_KEY_ID"
export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
export APP_STORE_CONNECT_API_KEY_PATH="/path/to/AuthKey_XXXX.p8"
```
