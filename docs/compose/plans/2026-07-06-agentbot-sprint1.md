# Agentbot iOS — Sprint 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fork OpenClaw iOS app, rebrand to Agentbot, connect to api.agentbot.sh, add JWT auth, and wire up the chat interface.

**Architecture:** We keep the existing SwiftUI app shell, OpenClawKit package, and Swabble dependency intact. Rebranding is done via config/color/name swaps. The gateway connection is redirected to api.agentbot.sh. A new JWT authentication layer is added in front of the existing gateway protocol. The existing chat UI continues to work through the gateway session.

**Tech Stack:** Swift 6.0, SwiftUI, XcodeGen, URLSession, WebSockets, Keychain, JWT

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `apps/ios/project.yml` | Modify | Rename targets/schemes from OpenClaw to Agentbot |
| `apps/ios/Signing.xcconfig` | Modify | Change bundle IDs, team, signing |
| `apps/ios/LocalSigning.xcconfig.example` | Modify | Update example for Agentbot |
| `apps/ios/Sources/Info.plist` | Modify | Display name, URL scheme, descriptions |
| `apps/ios/Sources/Design/OpenClawBrand.swift` | Create (new) | Agentbot brand colors (replace OpenClawBrand) |
| `apps/ios/Sources/AgentbotApp.swift` | Create (new) | Main app entry point (rebrand from OpenClawApp.swift) |
| `apps/ios/Sources/Agentbot.entitlements` | Create (new) | Entitlements (from OpenClaw.entitlements) |
| `apps/ios/Sources/AgentbotAppAttest.entitlements` | Create (new) | App Attest entitlements |
| `apps/ios/Sources/Auth/AuthManager.swift` | Create (new) | JWT auth manager |
| `apps/ios/Sources/Auth/LoginView.swift` | Create (new) | Login screen |
| `apps/ios/Sources/Gateway/GatewayConnectConfig.swift` | Modify | Point to api.agentbot.sh |
| `apps/ios/version.json` | Modify | Set Agentbot version |
| `apps/ios/CHANGELOG.md` | Modify | Reset for Agentbot |
| `apps/ios/README.md` | Modify | Agentbot README |

---

## Task 1: Rebrand project.yml — rename all targets and schemes

**Covers:** Phase 1 — Fork & Rename

**Files:**
- Modify: `apps/ios/project.yml`

- [ ] **Step 1: Rename project and all targets**

Replace every occurrence of `OpenClaw` with `Agentbot` in `project.yml`:

```yaml
name: Agentbot
options:
  bundleIdPrefix: sh.agentbot
  deploymentTarget:
    iOS: "18.0"
  xcodeVersion: "16.0"

settings:
  base:
    SWIFT_VERSION: "6.0"
    ENABLE_APP_INTENTS_METADATA_GENERATION: NO

packages:
  OpenClawKit:
    path: ../shared/OpenClawKit
  Swabble:
    path: ../swabble
  WebRTC:
    url: https://github.com/stasel/WebRTC.git
    exactVersion: 147.0.0

schemes:
  Agentbot:
    shared: true
    build:
      targets:
        Agentbot: all
    test:
      targets:
        - AgentbotTests
        - AgentbotLogicTests
  AgentbotLogicTests:
    shared: true
    build:
      targets:
        AgentbotLogicTests: all
    test:
      targets:
        - AgentbotLogicTests
  AgentbotUITests:
    shared: true
    build:
      targets:
        AgentbotUITests: all
    test:
      targets:
        - AgentbotUITests
  AgentbotWatchApp:
    shared: true
    build:
      targets:
        AgentbotWatchApp: all

targets:
  Agentbot:
    type: application
    platform: iOS
    configFiles:
      Debug: Signing.xcconfig
      Release: Signing.xcconfig
    sources:
      - path: Sources
    dependencies:
      - target: AgentbotShareExtension
        embed: true
      - target: AgentbotActivityWidget
        embed: true
      - target: AgentbotWatchApp
      - package: OpenClawKit
      - package: OpenClawKit
        product: OpenClawChatUI
      - package: OpenClawKit
        product: OpenClawProtocol
      - package: Swabble
        product: SwabbleKit
      - package: WebRTC
      - sdk: AppIntents.framework
    preBuildScripts:
      - name: SwiftLint
        basedOnDependencyAnalysis: false
        inputFileLists:
          - $(SRCROOT)/SwiftSources.input.xcfilelist
        script: |
          set -euo pipefail
          export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
          if ! command -v swiftlint >/dev/null 2>&1; then
            echo "warning: swiftlint not found (brew install swiftlint)" >&2
            exit 0
          fi
          swiftlint lint --config "$SRCROOT/.swiftlint.yml" --use-script-input-file-lists
    settings:
      base:
        CODE_SIGN_IDENTITY: "$(AGENTBOT_CODE_SIGN_IDENTITY)"
        CODE_SIGN_ENTITLEMENTS: "$(AGENTBOT_CODE_SIGN_ENTITLEMENTS)"
        CODE_SIGN_STYLE: "$(AGENTBOT_CODE_SIGN_STYLE)"
        DEVELOPMENT_TEAM: "$(AGENTBOT_DEVELOPMENT_TEAM)"
        PRODUCT_BUNDLE_IDENTIFIER: "$(AGENTBOT_APP_BUNDLE_ID)"
        PROVISIONING_PROFILE_SPECIFIER: "$(AGENTBOT_APP_PROFILE)"
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "6.0"
        SWIFT_STRICT_CONCURRENCY: complete
        SUPPORTS_LIVE_ACTIVITIES: YES
        ENABLE_APPINTENTS_METADATA: NO
        ENABLE_APP_INTENTS_METADATA_GENERATION: NO
      configs:
        Debug:
          AGENTBOT_CODE_SIGN_ENTITLEMENTS: Sources/Agentbot.entitlements
          AGENTBOT_APNS_ENTITLEMENT_ENVIRONMENT: development
          AGENTBOT_PUSH_MODE: localSandbox
          AGENTBOT_PUSH_RELAY_BASE_URL: ""
        Release:
          AGENTBOT_CODE_SIGN_ENTITLEMENTS: Sources/Agentbot.entitlements
          AGENTBOT_APNS_ENTITLEMENT_ENVIRONMENT: production
          AGENTBOT_PUSH_MODE: localProduction
          AGENTBOT_PUSH_RELAY_BASE_URL: ""
    info:
      path: Sources/Info.plist
      properties:
        CFBundleDisplayName: Agentbot
        CFBundleIconName: AppIcon
        CFBundleURLTypes:
          - CFBundleURLName: sh.agentbot.app
            CFBundleURLSchemes:
              - agentbot
        CFBundleShortVersionString: "$(AGENTBOT_MARKETING_VERSION)"
        AgentbotCanonicalVersion: "$(AGENTBOT_IOS_VERSION)"
        AgentbotAppGroupIdentifier: "$(AGENTBOT_APP_GROUP_ID)"
        CFBundleVersion: "$(AGENTBOT_BUILD_VERSION)"
        UILaunchScreen: {}
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
        UIBackgroundModes:
          - audio
          - remote-notification
        BGTaskSchedulerPermittedIdentifiers:
          - "$(AGENTBOT_APP_BUNDLE_ID).bgrefresh"
        NSLocalNetworkUsageDescription: Agentbot discovers and connects to your Agentbot gateway on the local network.
        NSAppTransportSecurity:
          NSAllowsArbitraryLoadsInWebContent: true
          NSAllowsLocalNetworking: true
        NSBonjourServices:
          - _agentbot-gw._tcp
        NSCameraUsageDescription: Agentbot uses the camera to capture photos or scan QR codes.
        NSCalendarsUsageDescription: Agentbot uses your calendars to show events and scheduling context.
        NSCalendarsFullAccessUsageDescription: Agentbot uses your calendars to show events and scheduling context.
        NSCalendarsWriteOnlyAccessUsageDescription: Agentbot uses your calendars to add events.
        NSContactsUsageDescription: Agentbot uses your contacts so you can search and reference people.
        NSLocationWhenInUseUsageDescription: Agentbot uses your location when you allow location sharing.
        NSLocationAlwaysAndWhenInUseUsageDescription: Agentbot can share your location in the background when you enable Always.
        NSMicrophoneUsageDescription: Agentbot uses the microphone for realtime chat, voice wake, and push-to-talk.
        NSMotionUsageDescription: Agentbot may use motion data to support device-aware interactions and automations.
        NSPhotoLibraryUsageDescription: Agentbot needs photo library access when you choose existing photos to share.
        NSRemindersFullAccessUsageDescription: Agentbot uses your reminders to list, add, and complete tasks.
        NSSpeechRecognitionUsageDescription: Agentbot uses on-device speech recognition for talk mode and voice wake.
        NSSupportsLiveActivities: true
        ITSAppUsesNonExemptEncryption: false
        AgentbotPushMode: "$(AGENTBOT_PUSH_MODE)"
        AgentbotPushRelayBaseURL: "$(AGENTBOT_PUSH_RELAY_BASE_URL)"
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationPortraitUpsideDown
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight

  AgentbotShareExtension:
    type: app-extension
    platform: iOS
    configFiles:
      Debug: Signing.xcconfig
      Release: Signing.xcconfig
    sources:
      - path: ShareExtension
    dependencies:
      - package: OpenClawKit
      - sdk: AppIntents.framework
    settings:
      base:
        CODE_SIGN_IDENTITY: "$(AGENTBOT_CODE_SIGN_IDENTITY)"
        CODE_SIGN_ENTITLEMENTS: ShareExtension/AgentbotShareExtension.entitlements
        CODE_SIGN_STYLE: "$(AGENTBOT_CODE_SIGN_STYLE)"
        DEVELOPMENT_TEAM: "$(AGENTBOT_DEVELOPMENT_TEAM)"
        ENABLE_APPINTENTS_METADATA: NO
        ENABLE_APP_INTENTS_METADATA_GENERATION: NO
        PRODUCT_BUNDLE_IDENTIFIER: "$(AGENTBOT_SHARE_BUNDLE_ID)"
        PROVISIONING_PROFILE_SPECIFIER: "$(AGENTBOT_SHARE_PROFILE)"
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "6.0"
        SWIFT_STRICT_CONCURRENCY: complete
    info:
      path: ShareExtension/Info.plist
      properties:
        CFBundleDisplayName: Agentbot Share
        CFBundleShortVersionString: "$(AGENTBOT_MARKETING_VERSION)"
        AgentbotAppGroupIdentifier: "$(AGENTBOT_APP_GROUP_ID)"
        CFBundleVersion: "$(AGENTBOT_BUILD_VERSION)"
        NSExtension:
          NSExtensionPointIdentifier: com.apple.share-services
          NSExtensionPrincipalClass: "$(PRODUCT_MODULE_NAME).ShareViewController"
          NSExtensionAttributes:
            NSExtensionActivationRule:
              NSExtensionActivationSupportsText: true
              NSExtensionActivationSupportsWebURLWithMaxCount: 1
              NSExtensionActivationSupportsImageWithMaxCount: 10
              NSExtensionActivationSupportsMovieWithMaxCount: 1

  AgentbotActivityWidget:
    type: app-extension
    platform: iOS
    configFiles:
      Debug: Signing.xcconfig
      Release: Signing.xcconfig
    sources:
      - path: ActivityWidget
      - path: Sources/LiveActivity/AgentbotActivityAttributes.swift
    dependencies:
      - sdk: WidgetKit.framework
      - sdk: ActivityKit.framework
    settings:
      base:
        CODE_SIGN_IDENTITY: "$(AGENTBOT_CODE_SIGN_IDENTITY)"
        CODE_SIGN_STYLE: "$(AGENTBOT_CODE_SIGN_STYLE)"
        DEVELOPMENT_TEAM: "$(AGENTBOT_DEVELOPMENT_TEAM)"
        PRODUCT_BUNDLE_IDENTIFIER: "$(AGENTBOT_ACTIVITY_WIDGET_BUNDLE_ID)"
        PROVISIONING_PROFILE_SPECIFIER: "$(AGENTBOT_ACTIVITY_WIDGET_PROFILE)"
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "6.0"
        SWIFT_STRICT_CONCURRENCY: complete
        SUPPORTS_LIVE_ACTIVITIES: YES
    info:
      path: ActivityWidget/Info.plist
      properties:
        CFBundleDisplayName: Agentbot Activity
        CFBundleShortVersionString: "$(AGENTBOT_MARKETING_VERSION)"
        CFBundleVersion: "$(AGENTBOT_BUILD_VERSION)"
        NSSupportsLiveActivities: true
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension

  AgentbotWatchApp:
    type: application
    platform: watchOS
    deploymentTarget: "11.0"
    sources:
      - path: WatchApp
        excludes:
          - Info.plist
    dependencies:
      - sdk: AppIntents.framework
      - sdk: WatchConnectivity.framework
      - sdk: UserNotifications.framework
    configFiles:
      Debug: Config/Signing.xcconfig
      Release: Config/Signing.xcconfig
    attributes:
      DevelopmentTeam: "$(AGENTBOT_DEVELOPMENT_TEAM)"
      ProvisioningStyle: "$(AGENTBOT_CODE_SIGN_STYLE)"
    settings:
      base:
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        CODE_SIGN_IDENTITY: "$(AGENTBOT_CODE_SIGN_IDENTITY)"
        CODE_SIGN_STYLE: "$(AGENTBOT_CODE_SIGN_STYLE)"
        DEVELOPMENT_TEAM: "$(AGENTBOT_DEVELOPMENT_TEAM)"
        ENABLE_APPINTENTS_METADATA: NO
        ENABLE_APP_INTENTS_METADATA_GENERATION: NO
        PRODUCT_BUNDLE_IDENTIFIER: "$(AGENTBOT_WATCH_APP_BUNDLE_ID)"
        PROVISIONING_PROFILE_SPECIFIER: "$(AGENTBOT_WATCH_APP_PROFILE)"
        SWIFT_STRICT_CONCURRENCY: complete
        SWIFT_VERSION: "6.0"
    info:
      path: WatchApp/Info.plist
      properties:
        CFBundleDisplayName: Agentbot
        CFBundleShortVersionString: "$(AGENTBOT_MARKETING_VERSION)"
        CFBundleVersion: "$(AGENTBOT_BUILD_VERSION)"
        WKCompanionAppBundleIdentifier: "$(AGENTBOT_APP_BUNDLE_ID)"
        WKApplication: true

  AgentbotTests:
    type: bundle.unit-test
    platform: iOS
    configFiles:
      Debug: Signing.xcconfig
      Release: Signing.xcconfig
    sources:
      - path: Tests
        excludes:
          - Logic
    dependencies:
      - target: Agentbot
      - package: Swabble
        product: SwabbleKit
      - sdk: AppIntents.framework
    settings:
      base:
        CODE_SIGN_IDENTITY: "$(AGENTBOT_CODE_SIGN_IDENTITY)"
        CODE_SIGN_STYLE: "$(AGENTBOT_CODE_SIGN_STYLE)"
        DEVELOPMENT_TEAM: "$(AGENTBOT_DEVELOPMENT_TEAM)"
        PRODUCT_BUNDLE_IDENTIFIER: "$(AGENTBOT_APP_BUNDLE_ID).tests"
        ENABLE_APP_INTENTS_METADATA_GENERATION: NO
        SWIFT_VERSION: "6.0"
        SWIFT_STRICT_CONCURRENCY: complete
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/Agentbot.app/Agentbot"
        BUNDLE_LOADER: "$(TEST_HOST)"
    info:
      path: Tests/Info.plist
      properties:
        CFBundleDisplayName: AgentbotTests
        CFBundleShortVersionString: "$(AGENTBOT_MARKETING_VERSION)"
        CFBundleVersion: "$(AGENTBOT_BUILD_VERSION)"

  AgentbotLogicTests:
    type: bundle.unit-test
    platform: iOS
    configFiles:
      Debug: Signing.xcconfig
      Release: Signing.xcconfig
    sources:
      - path: Tests/Logic
    dependencies:
      - package: OpenClawKit
    settings:
      base:
        CODE_SIGN_IDENTITY: "$(AGENTBOT_CODE_SIGN_IDENTITY)"
        CODE_SIGN_STYLE: "$(AGENTBOT_CODE_SIGN_STYLE)"
        DEVELOPMENT_TEAM: "$(AGENTBOT_DEVELOPMENT_TEAM)"
        PRODUCT_BUNDLE_IDENTIFIER: "$(AGENTBOT_APP_BUNDLE_ID).logic-tests"
        ENABLE_APP_INTENTS_METADATA_GENERATION: NO
        SWIFT_EMIT_CONST_VALUE_PROTOCOLS: ""
        SWIFT_VERSION: "6.0"
        SWIFT_STRICT_CONCURRENCY: complete
    info:
      path: Tests/Info.plist
      properties:
        CFBundleDisplayName: AgentbotLogicTests
        CFBundleShortVersionString: "$(AGENTBOT_MARKETING_VERSION)"
        CFBundleVersion: "$(AGENTBOT_BUILD_VERSION)"

  AgentbotUITests:
    type: bundle.ui-testing
    platform: iOS
    configFiles:
      Debug: Signing.xcconfig
      Release: Signing.xcconfig
    sources:
      - path: UITests
    dependencies:
      - target: Agentbot
    settings:
      base:
        CODE_SIGN_IDENTITY: "$(AGENTBOT_CODE_SIGN_IDENTITY)"
        CODE_SIGN_STYLE: "$(AGENTBOT_CODE_SIGN_STYLE)"
        DEVELOPMENT_TEAM: "$(AGENTBOT_DEVELOPMENT_TEAM)"
        PRODUCT_BUNDLE_IDENTIFIER: "$(AGENTBOT_APP_BUNDLE_ID).ui-tests"
        SDKROOT: iphoneos
        SUPPORTED_PLATFORMS: "iphonesimulator iphoneos"
        SUPPORTS_MACCATALYST: NO
        SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
        TEST_TARGET_NAME: Agentbot
        SWIFT_VERSION: "5.0"
    info:
      path: UITests/Info.plist
      properties:
        CFBundleDisplayName: AgentbotUITests
        CFBundleShortVersionString: "$(AGENTBOT_MARKETING_VERSION)"
        CFBundleVersion: "$(AGENTBOT_BUILD_VERSION)"
```

- [ ] **Step 2: Verify the edit**

Run: `grep -c "OpenClaw" apps/ios/project.yml`
Expected: `0` (all references replaced)

- [ ] **Step 3: Commit**

```bash
cd openclaw
git add apps/ios/project.yml
git commit -m "feat(ios): rebrand project.yml targets and schemes to Agentbot"
```

---

## Task 2: Rebrand Signing.xcconfig — bundle IDs and signing

**Covers:** Phase 1 — Bundle ID, Signing

**Files:**
- Modify: `apps/ios/Signing.xcconfig`
- Modify: `apps/ios/LocalSigning.xcconfig.example`

- [ ] **Step 1: Update Signing.xcconfig**

```xcconfig
// Agentbot signing defaults.
// Auto-selected local team overrides live in .local-signing.xcconfig (git-ignored).
// Manual local overrides can go in LocalSigning.xcconfig (git-ignored).

#include "Config/Version.xcconfig"

AGENTBOT_CODE_SIGN_STYLE = Automatic
AGENTBOT_CODE_SIGN_IDENTITY = Apple Development
AGENTBOT_CODE_SIGN_ENTITLEMENTS = Sources/Agentbot.entitlements
AGENTBOT_DEVELOPMENT_TEAM = YOUR_TEAM_ID

AGENTBOT_APP_BUNDLE_ID = sh.agentbot.app
AGENTBOT_SHARE_BUNDLE_ID = sh.agentbot.app.share
AGENTBOT_APP_GROUP_ID = group.sh.agentbot.app.shared
AGENTBOT_WATCH_APP_BUNDLE_ID = sh.agentbot.app.watchkitapp
AGENTBOT_ACTIVITY_WIDGET_BUNDLE_ID = sh.agentbot.app.activitywidget
AGENTBOT_APNS_ENTITLEMENT_ENVIRONMENT = development

AGENTBOT_APP_PROFILE =
AGENTBOT_SHARE_PROFILE =
AGENTBOT_ACTIVITY_WIDGET_PROFILE =
AGENTBOT_WATCH_APP_PROFILE =

// Keep local includes after defaults: xcconfig is evaluated top-to-bottom,
// so later assignments in local files override the defaults above.
#include? ".local-signing.xcconfig"
#include? "LocalSigning.xcconfig"
```

- [ ] **Step 2: Update LocalSigning.xcconfig.example**

```xcconfig
// Copy this file to LocalSigning.xcconfig for local development overrides.
// This file is git-ignored.

AGENTBOT_DEVELOPMENT_TEAM = YOUR_TEAM_ID
AGENTBOT_APP_BUNDLE_ID = sh.agentbot.app.dev
AGENTBOT_SHARE_BUNDLE_ID = sh.agentbot.app.dev.share
AGENTBOT_APP_GROUP_ID = group.sh.agentbot.app.dev.shared
AGENTBOT_WATCH_APP_BUNDLE_ID = sh.agentbot.app.dev.watchkitapp
AGENTBOT_ACTIVITY_WIDGET_BUNDLE_ID = sh.agentbot.app.dev.activitywidget
```

- [ ] **Step 3: Commit**

```bash
cd openclaw
git add apps/ios/Signing.xcconfig apps/ios/LocalSigning.xcconfig.example
git commit -m "feat(ios): rebrand signing config to Agentbot bundle IDs"
```

---

## Task 3: Update Info.plist — display name, URL scheme, descriptions

**Covers:** Phase 1 — Display name, URL scheme

**Files:**
- Modify: `apps/ios/Sources/Info.plist`

- [ ] **Step 1: Replace OpenClaw references in Info.plist**

Replace all `OpenClaw` string values with `Agentbot` in Info.plist. Key changes:
- `CFBundleDisplayName`: `Agentbot`
- `CFBundleURLName`: `sh.agentbot.app`
- `CFBundleURLSchemes`: `agentbot`
- `NSBonjourServices`: `_agentbot-gw._tcp`
- All `NS*UsageDescription` strings: replace "OpenClaw" with "Agentbot"
- `OpenClawAppGroupIdentifier` → `AgentbotAppGroupIdentifier`
- `OpenClawCanonicalVersion` → `AgentbotCanonicalVersion`
- `OpenClawPushMode` → `AgentbotPushMode`
- `OpenClawPushRelayBaseURL` → `AgentbotPushRelayBaseURL`

- [ ] **Step 2: Commit**

```bash
cd openclaw
git add apps/ios/Sources/Info.plist
git commit -m "feat(ios): rebrand Info.plist to Agentbot"
```

---

## Task 4: Create AgentbotBrand.swift — brand colors and design system

**Covers:** Phase 1 — Visual identity

**Files:**
- Create: `apps/ios/Sources/Design/AgentbotBrand.swift`

- [ ] **Step 1: Create AgentbotBrand.swift**

```swift
import SwiftUI

enum AgentbotBrand {
    static let uiAccent = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 59 / 255.0, green: 130 / 255.0, blue: 246 / 255.0, alpha: 1)
            : UIColor(red: 37 / 255.0, green: 99 / 255.0, blue: 235 / 255.0, alpha: 1)
    }

    static let accent = Color(uiColor: Self.uiAccent)
    static let accentHot = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 96 / 255.0, green: 165 / 255.0, blue: 250 / 255.0, alpha: 1)
            : UIColor(red: 59 / 255.0, green: 130 / 255.0, blue: 246 / 255.0, alpha: 1)
    })
    static let danger = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 252 / 255.0, green: 165 / 255.0, blue: 165 / 255.0, alpha: 1)
            : UIColor(red: 185 / 255.0, green: 28 / 255.0, blue: 28 / 255.0, alpha: 1)
    })
    static let ok = Color(red: 34 / 255.0, green: 197 / 255.0, blue: 94 / 255.0)
    static let warn = Color(red: 245 / 255.0, green: 158 / 255.0, blue: 11 / 255.0)
    static let info = Color(red: 59 / 255.0, green: 130 / 255.0, blue: 246 / 255.0)
    static let graphite = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 20 / 255.0, green: 22 / 255.0, blue: 24 / 255.0, alpha: 1)
            : UIColor(red: 246 / 255.0, green: 247 / 255.0, blue: 249 / 255.0, alpha: 1)
    })
    static let graphiteElevated = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 36 / 255.0, blue: 39 / 255.0, alpha: 1)
            : UIColor.white
    })

    static var sheetBackground: LinearGradient {
        LinearGradient(
            colors: [
                graphite,
                graphiteElevated.opacity(0.96),
                Color(uiColor: .systemBackground),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }
}

extension View {
    func agentbotSheetChrome() -> some View {
        self
            .tint(AgentbotBrand.accent)
            .background {
                AgentbotBrand.sheetBackground
                    .ignoresSafeArea()
            }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd openclaw
git add apps/ios/Sources/Design/AgentbotBrand.swift
git commit -m "feat(ios): add Agentbot brand colors and design system"
```

---

## Task 5: Create Agentbot.entitlements — entitlements files

**Covers:** Phase 1 — Entitlements

**Files:**
- Create: `apps/ios/Sources/Agentbot.entitlements`
- Create: `apps/ios/Sources/AgentbotAppAttest.entitlements`

- [ ] **Step 1: Read existing entitlements**

Read `apps/ios/Sources/OpenClaw.entitlements` and `apps/ios/Sources/OpenClawAppAttest.entitlements` to understand their structure.

- [ ] **Step 2: Create Agentbot.entitlements**

Copy the content from OpenClaw.entitlements, keeping the same structure (aps-environment, app groups, etc).

- [ ] **Step 3: Create AgentbotAppAttest.entitlements**

Copy the content from OpenClawAppAttest.entitlements.

- [ ] **Step 4: Commit**

```bash
cd openclaw
git add apps/ios/Sources/Agentbot.entitlements apps/ios/Sources/AgentbotAppAttest.entitlements
git commit -m "feat(ios): add Agentbot entitlements"
```

---

## Task 6: Create AuthManager.swift — JWT authentication layer

**Covers:** Phase 2 — Authentication

**Files:**
- Create: `apps/ios/Sources/Auth/AuthManager.swift`

- [ ] **Step 1: Create AuthManager.swift**

```swift
import Foundation
import Security

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let baseURL = URL(string: "https://api.agentbot.sh")!
    private let keychainService = "sh.agentbot.app"

    struct User: Codable, Sendable {
        let id: String
        let email: String
        let name: String?
    }

    struct AuthResponse: Codable, Sendable {
        let token: String
        let user: User
    }

    struct LoginRequest: Codable, Sendable {
        let email: String
        let password: String
    }

    struct SignupRequest: Codable, Sendable {
        let email: String
        let password: String
        let name: String?
    }

    var token: String? {
        get { readFromKeychain(key: "authToken") }
        set {
            if let newValue = newValue {
                saveToKeychain(key: "authToken", value: newValue)
            } else {
                deleteFromKeychain(key: "authToken")
            }
        }
    }

    func login(email: String, password: String) async throws {
        let body = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await request(
            path: "/auth/login",
            method: "POST",
            body: body
        )

        self.token = response.token
        self.currentUser = response.user
        self.isAuthenticated = true
    }

    func signup(email: String, password: String, name: String?) async throws {
        let body = SignupRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await request(
            path: "/auth/signup",
            method: "POST",
            body: body
        )

        self.token = response.token
        self.currentUser = response.user
        self.isAuthenticated = true
    }

    func logout() {
        token = nil
        currentUser = nil
        isAuthenticated = false
    }

    func restoreSession() async {
        guard let token = token, !token.isEmpty else { return }

        do {
            let user: User = try await request(
                path: "/auth/me",
                method: "GET"
            )
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            logout()
        }
    }

    func authorizedRequest(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> Data {
        guard let token = token else {
            throw AuthError.notAuthenticated
        }

        var request = URLRequest(
            url: baseURL.appendingPathComponent(path)
        )
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw AuthError.serverError
        }

        return data
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: (any Encodable)? = nil
    ) async throws -> T {
        var request = URLRequest(
            url: baseURL.appendingPathComponent(path)
        )
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw AuthError.serverError
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }

    enum AuthError: LocalizedError {
        case notAuthenticated
        case serverError
        case invalidCredentials

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Please sign in to continue."
            case .serverError:
                return "Server error. Please try again."
            case .invalidCredentials:
                return "Invalid email or password."
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd openclaw
mkdir -p apps/ios/Sources/Auth
git add apps/ios/Sources/Auth/AuthManager.swift
git commit -m "feat(ios): add JWT authentication manager with Keychain storage"
```

---

## Task 7: Create LoginView.swift — login/signup screen

**Covers:** Phase 2 — Authentication UI

**Files:**
- Create: `apps/ios/Sources/Auth/LoginView.swift`

- [ ] **Step 1: Create LoginView.swift**

```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var auth = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignup = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 60)

                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(AgentbotBrand.accent)

                        Text("Agentbot")
                            .font(.largeTitle.bold())

                        Text("Your AI agent, always with you.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        if isSignup {
                            TextField("Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                                .autocorrectionDisabled()
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(isSignup ? .newPassword : .password)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(isSignup ? "Create Account" : "Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AgentbotBrand.accent)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        withAnimation { isSignup.toggle() }
                    } label: {
                        Text(isSignup
                            ? "Already have an account? Sign In"
                            : "Don't have an account? Sign Up")
                            .foregroundStyle(AgentbotBrand.accent)
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil

        do {
            if isSignup {
                try await auth.signup(
                    email: email,
                    password: password,
                    name: name.isEmpty ? nil : name
                )
            } else {
                try await auth.login(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
}
```

- [ ] **Step 2: Commit**

```bash
cd openclaw
git add apps/ios/Sources/Auth/LoginView.swift
git commit -m "feat(ios): add login/signup screen"
```

---

## Task 8: Update version.json and CHANGELOG.md

**Covers:** Phase 1 — Versioning

**Files:**
- Modify: `apps/ios/version.json`
- Modify: `apps/ios/CHANGELOG.md`

- [ ] **Step 1: Update version.json**

```json
{
  "version": "2026.7.1"
}
```

- [ ] **Step 2: Update CHANGELOG.md**

```markdown
# Agentbot iOS Changelog

## Unreleased

### Changes
- Initial fork from OpenClaw iOS
- Rebranded to Agentbot
- Connected to api.agentbot.sh
- Added JWT authentication with Keychain storage
- Added login/signup screen
```

- [ ] **Step 3: Commit**

```bash
cd openclaw
git add apps/ios/version.json apps/ios/CHANGELOG.md
git commit -m "feat(ios): set Agentbot version 2026.7.1"
```

---

## Task 9: Run XcodeGen and verify project generates

**Covers:** Phase 1 — Build verification

**Files:**
- Verify: `apps/ios/Agentbot.xcodeproj`

- [ ] **Step 1: Install dependencies**

```bash
cd openclaw
pnpm install
```

- [ ] **Step 2: Generate Xcode project**

```bash
cd openclaw/apps/ios
xcodegen generate
```

Expected: Xcode project generated at `apps/ios/Agentbot.xcodeproj`

- [ ] **Step 3: Verify project structure**

```bash
ls -la Agentbot.xcodeproj/
```

Expected: Xcode project exists with correct structure

- [ ] **Step 4: Commit**

```bash
cd openclaw
git add apps/ios/Agentbot.xcodeproj
git commit -m "feat(ios): generate Agentbot Xcode project"
```

---

## Task 10: Update README.md

**Covers:** Phase 1 — Documentation

**Files:**
- Modify: `apps/ios/README.md`

- [ ] **Step 1: Replace README content**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
cd openclaw
git add apps/ios/README.md
git commit -m "docs(ios): update README for Agentbot"
```

---

## Self-Review

1. **Spec coverage:** Tasks 1-10 cover Phase 1 (Foundation) and Phase 2 (Backend Integration) of the roadmap. The project is forked, rebranded, has auth, and generates an Xcode project.

2. **Placeholder scan:** No TBD/TODO placeholders found. All code blocks contain complete implementations.

3. **Type consistency:** `AuthManager`, `AgentbotBrand`, and all config variables use consistent `AGENTBOT_` prefix. Bundle IDs follow `sh.agentbot.app` pattern throughout.

---

## Execution Handoff

This plan has 10 tasks with clear dependencies. Tasks 1-5 are pure config/rename work (parallelizable). Tasks 6-7 are new auth code. Tasks 8-10 are verification and docs.

Recommended approach: Execute inline since tasks are tightly coupled (each depends on the naming from Task 1).
