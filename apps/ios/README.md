# Agentbot iOS

iOS client for Agentbot — the operating system for AI agents.

## Quick Start

1. Install prerequisites:
   - Xcode 16+
   - `pnpm`
   - `xcodegen`

2. Generate the project:
   ```bash
   pnpm install
   cd apps/ios
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open Agentbot.xcodeproj
   ```

4. Select your development team and run.

## Architecture

- **UI:** SwiftUI
- **Auth:** JWT + Keychain
- **Backend:** api.agentbot.sh
- **Realtime:** WebSockets

## Configuration

Create `LocalSigning.xcconfig` for local development:

```xcconfig
AGENTBOT_DEVELOPMENT_TEAM = YOUR_TEAM_ID
AGENTBOT_APP_BUNDLE_ID = sh.agentbot.app.dev
```

## License

MIT
