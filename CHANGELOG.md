# Changelog

All notable changes to ZenDevToolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0-beta.8] - 2025-08-12

### Improved
- **JSON Formatter**: Complete rewrite to preserve element order
  - JSON objects now maintain their original key order during format/minify operations  
  - Implemented custom tokenizer-based parser for robust handling of complex JSON structures
  - Enhanced string literal processing with proper escape sequence support (quotes, backslashes, unicode)
  - Maintains full JSONSerialization validation for error detection while preserving order
  - Supports all JSON data types: nested objects, arrays, strings with special characters, numbers (including scientific notation), booleans, and null values
  - Improved handling of edge cases that could break simpler string-based formatters

## [1.0.0-beta.7] - 2025-08-11

### Fixed
- **Dock Visibility Issue**: App now properly hides from dock and runs as pure menu bar application
  - Fixed LSUIElement configuration in Xcode project settings
  - Resolved Info.plist generation issue that was ignoring source Info.plist
  - App no longer appears in dock, maintaining clean menu bar-only experience
  - Updated version numbering to 1.0.0-beta.6 in built app

## [1.0.0-beta.6] - 2025-08-11

### Improved
- **About Screen Enhancement**: Personalized About panel with developer attribution
  - Updated Info.plist to display correct beta version (1.0.0-beta.5)
  - Replaced generic copyright with creative personal attribution: "Made with ❤️ by Dileesha R. • github.com/dilee"
  - Added application description for better About panel presentation
  - Simplified About screen implementation using standard macOS panel for better reliability

## [1.0.0-beta.5] - 2025-01-11

### Added
- File upload functionality for JSON formatter
  - New "File" button to load JSON files directly
  - Supports .json, .txt, and plain text files
  - Automatic validation on file load

### Improved
- **UI Polish**: Modernized scrollbar appearance across all text editors
  - Overlay-style scrollbars that auto-hide when not in use
  - Light knob style for better visibility in dark mode
  - Consistent scrollbar behavior across all tools
- **Text Editor Consistency**: Extended UndoableTextEditor to all tools
  - URL encoder now has undo/redo support
  - Hash generator has improved text editing
  - Base64 encoder/decoder has better text handling
- **Visual Refinements**:
  - Centered all placeholder texts for cleaner appearance
  - Fixed UUID generator spacing (top and bottom padding)
  - Improved overall visual consistency

### Changed
- All text input areas now use the custom UndoableTextEditor component
- Placeholder texts are now centered both horizontally and vertically

## [1.0.0-beta.4] - 2025-01-11

### Added
- Undo/Redo support for all text editors
  - Standard keyboard shortcuts (⌘Z/⌘⇧Z)
  - Full undo history for each tool
  - Custom UndoableTextEditor component

### Fixed
- **Critical**: App now properly appears above fullscreen applications
  - Changed from NSWindow to NSPanel for better window management
  - Uses assistive technology window level for maximum visibility
  - Added proper collection behaviors for fullscreen spaces
- Improved window focus and text field activation

### Changed
- Window system completely refactored for better macOS integration
- Enhanced window positioning and display logic

## [1.0.0-beta.3] - 2025-01-11

### Added
- Full code signing with Developer ID Application certificate
- Automated notarization in CI/CD pipeline
- Hardened runtime for enhanced security
- App sandboxing with appropriate entitlements

### Fixed
- CI/CD build process now properly uses Developer ID certificates
- Code signing verification in GitHub Actions workflow
- Export options configuration for manual signing

### Changed
- Switched from ad-hoc signing to Developer ID signing
- App is now fully trusted by macOS Gatekeeper (no security warnings)
- Improved release automation with proper certificate handling

## [1.0.0-beta.2] - 2025-01-10

### Added
- Custom app icon replacing the placeholder
- Ad-hoc code signing for slightly better Gatekeeper behavior

### Fixed
- GitHub Actions workflow now uses modern release action
- Removed deprecated GitHub Actions commands

### Changed
- Updated release notes to include security information for unsigned apps

## [1.0.0-beta.1] - 2025-01-10

### Added
- Initial beta release of ZenDevToolkit
- **JSON Formatter & Validator**
  - Format/beautify with proper indentation
  - Minify (remove whitespace)
  - Real-time validation with error messages
  - Keyboard shortcut (⌘+Return to format)
- **Base64 Encoder/Decoder**
  - Text and file support
  - URL-safe encoding option
  - Line breaks formatting option
  - File size warnings
- **URL Encoder/Decoder**
  - Full URL encoding
  - Component encoding
  - Form data encoding
  - URL analysis with component breakdown
- **Hash Generator**
  - MD5, SHA1, SHA256 algorithms
  - HMAC support with secret key
  - File hashing capability
  - Hash comparison tool
- **UUID Generator**
  - Version 4 UUIDs
  - Multiple format options (hyphens, uppercase, URN, braces)
  - Bulk generation
  - Smart reformatting
- Menu bar integration with shippingbox.fill icon
- Dark mode support
- Resizable popover window (320×400 to 600×800)
- Keyboard shortcuts for common actions
- Clipboard integration throughout

### Known Issues
- This is a beta release - please report any bugs on GitHub

### Planned for v1.0.0
- Performance optimizations
- Additional keyboard shortcuts
- Bug fixes based on user feedback

[Unreleased]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.8...HEAD
[1.0.0-beta.8]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.7...v1.0.0-beta.8
[1.0.0-beta.7]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.6...v1.0.0-beta.7
[1.0.0-beta.6]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.5...v1.0.0-beta.6
[1.0.0-beta.5]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.4...v1.0.0-beta.5
[1.0.0-beta.4]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.3...v1.0.0-beta.4
[1.0.0-beta.3]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.2...v1.0.0-beta.3
[1.0.0-beta.2]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.1...v1.0.0-beta.2
[1.0.0-beta.1]: https://github.com/dilee/zen-dev-toolkit/releases/tag/v1.0.0-beta.1