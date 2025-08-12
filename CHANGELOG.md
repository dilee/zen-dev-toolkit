# Changelog

All notable changes to ZenDevToolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.2] - 2025-08-13

### Fixed
- **Update Notification Banner**: Completely redesigned update notification system for better UX
  - Moved banner to bottom of window to prevent UI overlap
  - Window now dynamically expands by 50px when update is available
  - Added smooth animations for banner appearance/dismissal
  - Fixed issue where banner overlapped with tool selector buttons
  - Banner now uses semi-transparent background (75% opacity) for modern look
  - All tool buttons remain fully accessible when banner is shown

### Improved
- **Update Experience**: 
  - Banner dismissal now smoothly resizes window back to original size
  - Connected banner to actual UpdateChecker logic
  - Display real version numbers from update checker
  - Better visual hierarchy with update info at bottom

## [1.0.1] - 2025-08-13

### Added
- **Smart Update Detection**: Automatically detects installation method (Homebrew vs direct download)
- **Installation-Specific Update Instructions**: 
  - Homebrew users see `brew upgrade` command with copy button
  - Direct download users get download link to latest release
- **Release Process Documentation**: Comprehensive release instructions in CLAUDE.md
- **Release Template**: Standardized template for consistent release notes

### Fixed
- **JWT Tool**: Removed unsupported RS256 algorithm option that was causing errors
- **Update Checker**: Simplified implementation, accepting harmless QoS warnings

### Improved
- **Release Workflow**: Now includes both installation and upgrade instructions
- **Update Experience**: Better guidance for users based on their installation method

## [1.0.0] - 2025-08-13

### Added
- **Auto Update Checker**: Lightweight update notification system
  - Automatic check for updates on app launch (once per 24 hours)
  - Manual update check via right-click menu
  - Non-intrusive update notification banner
  - Support for both Homebrew and direct download distribution
  - Version comparison with pre-release support
  - Skip specific versions option
  - Network client entitlement for GitHub API access

### Changed
- **Stable Release**: Graduating from beta to stable version 1.0.0
- All core features are now production-ready
- Improved error handling and user experience across all tools

### Summary
ZenDevToolkit 1.0.0 is the first stable release, featuring 7 essential developer tools:
- JSON Formatter with JSONPath queries
- Base64 Encoder/Decoder
- URL Encoder/Decoder  
- Hash Generator
- UUID Generator
- Timestamp Converter
- JWT Token Tool

The app is lightweight, fast, and designed for developers who need quick access to common utilities without opening a browser.

## [1.0.0-beta.11] - 2025-08-12

### Added
- **JWT Token Tool**: Comprehensive JWT token manipulation utility
  - Decode JWT tokens to view header, payload, and signature sections
  - Generate new JWT tokens with custom claims and expiration
  - Verify JWT signatures with secret key validation
  - Support for HMAC algorithms (HS256, HS384, HS512)
  - Human-readable claims display with expiration tracking
  - Toggle between readable and JSON views for payload data
  - Real-time token validation and error feedback
  - Copy individual sections or entire tokens to clipboard

### Fixed
- JWT view text areas now have consistent width with other tool views
- Fixed deprecated `onChange` warning in JSONFormatterView
- Improved button height consistency in URL encoder view

## [1.0.0-beta.10] - 2025-08-12

### Added
- **Timestamp Converter**: New tool for timestamp conversion operations
  - Convert Unix timestamps to human-readable dates
  - Convert human dates to Unix timestamps  
  - Support for multiple timezones (Local, UTC, EST, PST, GMT, etc.)
  - Multiple date format options (ISO, US, European, compact formats)
  - Relative time display showing "time ago" format (e.g., "2 hours ago")
  - Real-time conversion with input validation
  - Copy results to clipboard functionality
  - Clean, intuitive interface following app design patterns

## [1.0.0-beta.9] - 2025-08-12

### Added
- **JSONPath Query Support**: New tab-based interface for querying JSON data
  - Switch between Format and Query modes with clean tab interface
  - Custom JSONPath parser supporting common query patterns:
    - Property access: `$.store.book[0].title`
    - Recursive descent: `$..price`
    - Array operations: indexing, slicing, wildcards
    - Basic filter expressions: `$[?(@.price < 10)]`
  - Quick-access example buttons for common patterns
  - Real-time query execution with error feedback
  - Copy query results to clipboard
  - Maintains same 420x680px window size with zero UI clutter

### Improved
- **Button Interaction**: Enhanced click targets for all buttons
  - Tab buttons now have proper 8pt spacing between them
  - Entire button area is now clickable, not just text/icon
  - Better user experience with larger hit targets

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

[Unreleased]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.11...v1.0.0
[1.0.0-beta.11]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.10...v1.0.0-beta.11
[1.0.0-beta.10]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.9...v1.0.0-beta.10
[1.0.0-beta.8]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.7...v1.0.0-beta.8
[1.0.0-beta.7]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.6...v1.0.0-beta.7
[1.0.0-beta.6]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.5...v1.0.0-beta.6
[1.0.0-beta.5]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.4...v1.0.0-beta.5
[1.0.0-beta.4]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.3...v1.0.0-beta.4
[1.0.0-beta.3]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.2...v1.0.0-beta.3
[1.0.0-beta.2]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.1...v1.0.0-beta.2
[1.0.0-beta.1]: https://github.com/dilee/zen-dev-toolkit/releases/tag/v1.0.0-beta.1