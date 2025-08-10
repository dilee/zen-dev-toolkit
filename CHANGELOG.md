# Changelog

All notable changes to ZenDevToolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.2...HEAD
[1.0.0-beta.2]: https://github.com/dilee/zen-dev-toolkit/compare/v1.0.0-beta.1...v1.0.0-beta.2
[1.0.0-beta.1]: https://github.com/dilee/zen-dev-toolkit/releases/tag/v1.0.0-beta.1