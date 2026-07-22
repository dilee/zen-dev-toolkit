# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ZenDevToolkit is a lightweight macOS menu bar application that provides developers with quick access to commonly-needed utility functions without opening a web browser. The app lives in the system menu bar and opens a clean, organized popup interface (360x500px) when clicked.

**Target Platform**: macOS native app for Mac App Store distribution ($3.99 one-time purchase)
**Target Users**: Software developers who frequently need to format JSON, encode/decode data, generate hashes, and perform other common development tasks

## Architecture

### Core Components

- **ZenDevToolkitApp.swift**: Main app entry point with menu bar setup via AppDelegate
  - Manages NSStatusItem for menu bar presence
  - Controls a custom borderless NSPanel (ToolkitPanel, 420×680) hosting ContentView
  - Installs the ⌘1–⌘7 local key monitor and the global hotkey (via HotkeyManager)
  - Right-click menu: About, Check for Updates (Homebrew builds), Launch at Login (SMAppService), Global Hotkey presets, Quit

- **ContentView.swift**: Main UI container that hosts all tools
  - Compact icon tool buttons in a fixed header (order defined by `AppState.toolTags`)
  - Last-used tool persisted via `@AppStorage("selectedTool")`
  - Pin toggle to keep the panel open when clicking outside

- **AppState.swift**: Shared session state (pin) and the canonical tool-tag order
- **HotkeyManager.swift**: Global hotkey registration via Carbon `RegisterEventHotKey` (presets: off/⌃⌥Space/⌥Space/⌃⌥Z, persisted in `globalHotkeyPreset`)
- **UndoableTextEditor.swift**: Shared NSTextView wrapper used by all text-based tools (undo/redo, monospace)
- **UpdateChecker.swift / UpdateNotificationView.swift**: GitHub-release update check (compiled out in App Store builds)

### Tool Views

Each tool is implemented as a separate SwiftUI view — all fully implemented:
- JSONFormatterView (+ JSONPathParser): format/minify/validate plus a JSONPath query tab
- Base64View (+ ImageDataInspector): text/file/drag-drop encode-decode, URL-safe and line-break options, `data:` URI stripping, image preview with Copy Image/Save for decoded images
- URLEncoderView: encode/decode/analyze with URL component breakdown
- HashGeneratorView: MD5/SHA-1/SHA-256/384/512, HMAC, file hashing, hash compare
- UUIDGeneratorView (+ UUIDv7): v4 and time-ordered v7 (RFC 9562), formats, bulk generation
- TimestampConverterView: Unix/human conversion with timezone support
- JWTView: decode/generate/verify (HS256/HS384/HS512)

## Build Configuration

### Single Branch Strategy

The project now uses a single `main` branch for both Homebrew and App Store distribution. The auto-updater feature is **enabled by default** and conditionally disabled with the `DISABLE_AUTO_UPDATE` flag:

- **Default builds (Debug/Release)**: Auto-updater enabled
- **GitHub Actions/Homebrew**: Auto-updater enabled (default)
- **App Store builds**: Auto-updater disabled (use Debug-AppStore or add DISABLE_AUTO_UPDATE flag)

This approach is App Store compliant as disabled code paths are acceptable for review.

## Development Commands

### Build and Run
```bash
# Build for Development/Homebrew (auto-updater enabled by default)
xcodebuild -scheme ZenDevToolkit -configuration Debug

# Build for App Store (auto-updater disabled)
xcodebuild -scheme ZenDevToolkit -configuration Debug \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS="DISABLE_AUTO_UPDATE"

# Build for release (Homebrew - auto-updater enabled by default)
xcodebuild -scheme ZenDevToolkit -configuration Release

# Build for release (App Store - auto-updater disabled)
xcodebuild -scheme ZenDevToolkit -configuration Release \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS="DISABLE_AUTO_UPDATE"

# Clean build folder
xcodebuild -scheme ZenDevToolkit clean
```

### Signed Release Build
```bash
# Build, sign, and prepare for distribution
./scripts/build-release.sh

# This script:
# - Creates a signed archive
# - Exports with Developer ID certificate
# - Verifies code signature
# - Creates ZIP for notarization
# - Optionally submits for notarization (if credentials are set)
```

### Code Signing & Notarization

The app is configured for trusted distribution with:
- **Team ID**: 3Z86BP8YAG (Dileesha Rajapakse)
- **Bundle ID**: com.luminaxa.ZenDevToolkit
- **Code Signing**: Automatic with Developer ID Application certificate
- **Hardened Runtime**: Enabled
- **Sandboxing**: Enabled with file access permissions

#### Manual Notarization
```bash
# Set credentials (required for notarization)
export APPLE_ID="dilee.dev@gmail.com"
export APPLE_APP_PASSWORD="your-app-specific-password"

# Notarize the built app
./scripts/notarize.sh build/export-distribution/ZenDevToolkit.app

# Or notarize a ZIP file
./scripts/notarize.sh build/ZenDevToolkit.zip
```

#### Creating App-Specific Password
1. Go to https://appleid.apple.com/ (sign in with dilee.dev@gmail.com)
2. Navigate to Security section
3. Generate app-specific password for "ZenDevToolkit Notarization"
4. Use this password as `APPLE_APP_PASSWORD`

### Testing
```bash
# Run all tests
xcodebuild test -scheme ZenDevToolkit -destination 'platform=macOS'

# Run specific test target
xcodebuild test -scheme ZenDevToolkit -only-testing:ZenDevToolkitTests
```

### Open in Xcode
```bash
open ZenDevToolkit.xcodeproj
```

## Features

1. **JSON Formatter & Validator** ✅ (Implemented)
   - Format, minify, validate with error messages
   - JSONPath query tab (property access, recursive descent, slices, basic filters)
   - Clipboard integration, monospace font display

2. **Base64 Encoder/Decoder** ✅ (Implemented)
   - Text, file, and drag-and-drop input; URL-safe and line-break options
   - Automatic `data:<mime>;base64,` prefix stripping on decode
   - Image preview for decoded images (thumbnail, dimensions, Copy Image, Save)

3. **URL Encoder/Decoder** ✅ (Implemented)
   - Standard/component/form-data encoding modes
   - Analyze mode with component breakdown and query params as JSON

4. **Hash Generator** ✅ (Implemented)
   - MD5, SHA-1, SHA-256, SHA-384, SHA-512 with HMAC support
   - File hashing and hash comparison

5. **UUID Generator** ✅ (Implemented)
   - Version 4 (random) and Version 7 (time-ordered, RFC 9562) UUIDs
   - Multiple format options, bulk generation

6. **Timestamp Converter** ✅ (Implemented)
   - Convert Unix timestamps to human-readable dates
   - Convert human dates to Unix timestamps
   - Support for multiple timezones
   - Multiple date format support
   - Relative time display ("2 hours ago")

7. **JWT Token Tool** ✅ (Implemented)
   - Decode JWT tokens with header, payload, and signature display
   - Generate JWT tokens with custom claims
   - Verify JWT signatures with secret key validation
   - Support for HMAC algorithms (HS256, HS384, HS512)
   - Human-readable claims display with expiration tracking
   - Toggle between readable and JSON views for payload
   - Base64URL encoding/decoding for JWT format compliance

8. **App Shell / Quality of Life** ✅ (Implemented)
   - Global hotkey to toggle the popover (presets: ⌃⌥Space, ⌥Space, ⌃⌥Z; off by default; Carbon `RegisterEventHotKey`, App Store safe)
   - Launch at Login via `SMAppService` (right-click menu toggle)
   - ⌘1–⌘7 tool switching (local key monitor, active only while the panel is key)
   - Last-used tool remembered across launches (`@AppStorage("selectedTool")`)
   - Pin toggle to keep the panel open while clicking other apps (session-only, gates both the event-monitor and `resignKey` dismissal paths)

## Key Implementation Notes

- The app uses SwiftUI for all UI components
- Menu bar integration is handled through AppDelegate pattern with NSStatusItem
- The app uses the new Swift Testing framework (`import Testing`) rather than XCTest
- NSPasteboard is used for clipboard operations (copy/paste functionality)
- The popover behavior is set to `.transient` (dismisses when clicking outside)
- App should launch in <1 second for optimal developer workflow

## Adding New Tools

To add a new tool:
1. Create a new SwiftUI View in a separate file (it joins the target automatically — the project uses Xcode synchronized folder groups, so never edit project.pbxproj by hand)
2. Add a `CompactToolButton` to the header row in ContentView and a case to its switch statement
3. Append the tool's tag to `AppState.toolTags` in the same position as its header button (this drives the ⌘1–⌘9 shortcuts and tooltips)
4. Implement the tool's functionality following the JSONFormatterView pattern (UndoableTextEditor for text areas, ⌘Return for the primary action)

## UI/UX Guidelines

### Design Principles

The design language (exemplar: Base64View.swift — read it before styling anything):
- The panel sits on a translucent `NSVisualEffectView` material (`VisualEffectBackground`); tool views must NOT set an opaque root background
- Mode/tab choices are native segmented `Picker`s (`.pickerStyle(.segmented)`, `.labelsHidden()`, `.fixedSize()` when compact); boolean options are small native checkboxes (`.toggleStyle(.checkbox)`, `.controlSize(.small)`, no icons in labels)
- Prefer live processing on input change over explicit action buttons; keep buttons only for genuine transformations (Format, Generate) as native `.borderedProminent`/`.bordered` — never full-width custom shapes
- Section labels: 11pt medium `.secondary`; utility actions (Paste/File/Clear/Save/Swap) are icon-only 12pt secondary buttons with `.help()` tooltips; at most ONE accent action per header row (usually Copy, icon + 11pt text)
- Content containers: `RoundedRectangle(cornerRadius: 8)` filled `Color.primary.opacity(0.04)` with a `Color.secondary.opacity(0.15)` hairline border; red border only for errors; success is a green checkmark icon in the header, never a green border
- Placeholders: system font 12 (monospace is for content only), `secondary.opacity(0.5)`, top-leading, no trailing "..."
- Rhythm: 16pt horizontal padding, section VStacks spacing 8, header rows `HStack(spacing: 10)`, top controls row `.padding(.top, 14).padding(.bottom, 10)`

### Performance Requirements
- Launch time must be <1 second
- All operations should feel instant (no loading spinners for local operations)
- Lightweight memory footprint for always-running menu bar app

### Future Enhancements (Post v1.1)
- Regex tester and matcher
- Color converter (hex, RGB, HSL) with native eyedropper (NSColorSampler)
- QR code generator
- Cron expression explainer
- Smart clipboard detection (route clipboard content to the matching tool; mind macOS 15.4 pasteboard privacy prompts)
- Tool visibility settings once the tab count outgrows the header row
- Bulk file processing

## Release Process

### Creating a New Release

When preparing a new release, follow these steps:

#### Building for Different Platforms

**For Homebrew Release (GitHub)**:
- The GitHub Actions workflow automatically builds with auto-updater enabled (default)
- Just create and push a tag to trigger the release

**For App Store Submission**:
```bash
# Build with auto-updater disabled for App Store
xcodebuild -scheme ZenDevToolkit \
  -configuration Release \
  -archivePath build/ZenDevToolkit.xcarchive \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS="DISABLE_AUTO_UPDATE" \
  archive

# Export for App Store Connect
xcodebuild -exportArchive \
  -archivePath build/ZenDevToolkit.xcarchive \
  -exportPath build/export-appstore \
  -exportOptionsPlist scripts/ExportOptions-AppStore.plist
```

**Using Xcode UI**:
- For regular development: Use the default `ZenDevToolkit` scheme (auto-updater enabled)
- For App Store testing: Use the `ZenDevToolkit` scheme with `Debug-AppStore` configuration

1. **Update Version Numbers** (4 places):
   - `ZenDevToolkit/Info.plist`: Update both `CFBundleShortVersionString` (e.g., "1.0.1") and `CFBundleVersion` (e.g., "101")
   - `ZenDevToolkit.xcodeproj/project.pbxproj`: Update `MARKETING_VERSION` (this overrides Info.plist's `CFBundleShortVersionString`!)
     - Search for `MARKETING_VERSION = x.x.x;` and update ALL occurrences
   - `ZenDevToolkit.xcodeproj/project.pbxproj`: Update `CURRENT_PROJECT_VERSION` (this overrides Info.plist's `CFBundleVersion`! App Store validation rejects uploads whose build number doesn't increase)
     - Search for `CURRENT_PROJECT_VERSION = n;` and update ALL occurrences
   - `README.md`: Update the version badge

2. **Update Documentation**:
   - `CHANGELOG.md`: Add new version section with release notes
   - Move items from `[Unreleased]` to the new version section
   - Update the comparison links at the bottom

3. **Commit Changes**:
   ```bash
   git add -A
   git commit -m "feat: release version X.X.X"
   ```

4. **Create and Push Tag**:
   ```bash
   git tag -a vX.X.X -m "Release version X.X.X"
   git push origin main
   git push origin vX.X.X
   ```

5. **GitHub Actions will automatically**:
   - Build and sign the app
   - Create a GitHub release
   - Upload the built artifacts

6. **After CI/CD completes, update the release description**:
   - Use `.github/RELEASE_TEMPLATE.md` as a guide
   - Include both installation AND upgrade instructions
   - Add checksums from the built artifacts
   - Link to the full changelog

### Important Notes
- **MARKETING_VERSION and CURRENT_PROJECT_VERSION in project.pbxproj override Info.plist** - Always update all of them!
- Only create the tag after all version updates are committed
- Use semantic versioning (MAJOR.MINOR.PATCH)
- The CI/CD pipeline triggers on tags starting with 'v'
- Always include upgrade instructions for both Homebrew and direct download users

## Important Instructions

### Git Commit Rules
- NEVER include any mentions of Claude, AI, or automated generation in commit messages
- Write commit messages as if they were written by a human developer
- Keep commit messages professional and focused solely on the changes made
- Use conventional commit format (feat:, fix:, docs:, etc.) when appropriate