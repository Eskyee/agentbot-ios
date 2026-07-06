#!/bin/bash
set -euo pipefail

# Agentbot TestFlight Build Script
# Usage: ./scripts/build-testflight.sh [--upload]

echo "🤖 Agentbot TestFlight Build"
echo "============================"

# Check prerequisites
command -v xcodebuild >/dev/null 2>&1 || { echo "❌ xcodebuild not found"; exit 1; }
command -v xcodegen >/dev/null 2>&1 || { echo "❌ xcodegen not found. Install: brew install xcodegen"; exit 1; }

# Read version from version.json
VERSION=$(python3 -c "import json; print(json.load(open('apps/ios/version.json'))['version'])")
echo "📦 Version: $VERSION"

# Generate project
echo "⚙️  Generating Xcode project..."
cd apps/ios
xcodegen generate
cd ../..

# Clean
echo "🧹 Cleaning build..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Agentbot-*

# Build archive
echo "🔨 Building archive..."
xcodebuild \
    -project apps/ios/Agentbot.xcodeproj \
    -scheme Agentbot \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "build/Agentbot.xcarchive" \
    -xcconfig apps/ios/TestFlight.xcconfig \
    clean archive \
    CODE_SIGNING_ALLOWED=NO

echo "✅ Archive created: build/Agentbot.xcarchive"

# Export IPA
echo "📱 Exporting IPA..."
cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

xcodebuild \
    -exportArchive \
    -archivePath "build/Agentbot.xcarchive" \
    -exportOptionsPlist build/ExportOptions.plist \
    -exportPath "build/AppStore"

echo "✅ IPA exported: build/AppStore/Agentbot.ipa"

# Upload to TestFlight if --upload flag
if [[ "${1:-}" == "--upload" ]]; then
    echo "🚀 Uploading to TestFlight..."
    command -v xcrun >/dev/null 2>&1 || { echo "❌ xcrun not found"; exit 1; }
    
    xcrun altool --upload-app \
        --type ios \
        --file "build/AppStore/Agentbot.ipa" \
        --apiKey "${APP_STORE_CONNECT_API_KEY:-}" \
        --apiIssuer "${APP_STORE_CONNECT_ISSUER_ID:-}"
    
    echo "✅ Uploaded to TestFlight!"
else
    echo ""
    echo "📋 To upload to TestFlight:"
    echo "   1. Open Xcode → Window → Organizer"
    echo "   2. Select the Agentbot archive"
    echo "   3. Click 'Distribute App' → 'App Store Connect'"
    echo "   4. Or run: $0 --upload"
fi

echo ""
echo "🎉 Build complete! Version: $VERSION"
