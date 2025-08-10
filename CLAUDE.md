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
  - Controls NSPopover for tool interface (360x500 size)
  
- **ContentView.swift**: Main UI container that hosts all tools
  - Segmented picker for tool selection
  - Currently implements JSON formatter with placeholder views for other tools

### Tool Views

Each tool is implemented as a separate SwiftUI view:
- JSONFormatterView: Fully implemented with format/minify/validate functionality
- Base64View, URLEncoderView, HashGeneratorView, UUIDGeneratorView: Placeholder implementations

## Development Commands

### Build and Run
```bash
# Build the app
xcodebuild -scheme ZenDevToolkit -configuration Debug

# Build for release
xcodebuild -scheme ZenDevToolkit -configuration Release

# Clean build folder
xcodebuild -scheme ZenDevToolkit clean
```

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

## Planned Features (v1.0)

1. **JSON Formatter & Validator** ✅ (Implemented)
   - Format, minify, validate with error messages
   - Clipboard integration, monospace font display

2. **Base64 Encoder/Decoder** (Placeholder)
   - Text and file support planned
   - Bidirectional encoding/decoding

3. **URL Encoder/Decoder** (Placeholder)
   - Percent-encoding for URLs
   - Query parameter handling

4. **Hash Generator** (Placeholder)
   - MD5, SHA1, SHA256 support planned
   - Uses CommonCrypto framework

5. **UUID Generator** (Placeholder)
   - Version 4 UUIDs
   - Multiple format options

## Key Implementation Notes

- The app uses SwiftUI for all UI components
- Menu bar integration is handled through AppDelegate pattern with NSStatusItem
- The app uses the new Swift Testing framework (`import Testing`) rather than XCTest
- NSPasteboard is used for clipboard operations (copy/paste functionality)
- The popover behavior is set to `.transient` (dismisses when clicking outside)
- App should launch in <1 second for optimal developer workflow

## Adding New Tools

To add a new tool:
1. Create a new SwiftUI View in ContentView.swift or a separate file
2. Add a new case to the Picker in ContentView
3. Add the corresponding case in the switch statement
4. Implement the tool's functionality following the JSONFormatterView pattern

## UI/UX Guidelines

### Design Principles
- Clean, minimalist interface that adapts to macOS light/dark mode
- Tools follow a consistent layout: input area → action buttons → output area
- Use `.buttonStyle(.borderedProminent)` for primary actions
- Use `.buttonStyle(.bordered)` for secondary actions
- Include copy/paste buttons for user convenience
- Show validation feedback with visual indicators (checkmarks, error messages)

### Performance Requirements
- Launch time must be <1 second
- All operations should feel instant (no loading spinners for local operations)
- Lightweight memory footprint for always-running menu bar app

### Future Enhancements (Post v1.0)
- Regex tester and matcher
- Color converter (hex, RGB, HSL)
- Timestamp converter
- QR code generator
- Custom keyboard shortcuts
- Bulk file processing