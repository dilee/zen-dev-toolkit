# ZenDevToolkit (Beta)

![ZenDevToolkit Hero Banner](Docs/Marketing/Banners/hero-banner.png)

A lightweight macOS menu bar application that provides developers with quick access to commonly-needed utility functions without opening a web browser.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0--beta.9-yellow)

## 🚀 Features

### Currently Implemented ✅

- **JSON Formatter & Validator**
  - Format/beautify JSON with proper indentation
  - Minify JSON (remove whitespace)
  - Validate JSON syntax with clear error messages
  - Real-time validation as you type
  - File upload support for JSON files
  - Copy/paste integration with system clipboard
  - Keyboard shortcuts (⌘+Return to format)
  - **NEW: JSONPath Query Support**
    - Query JSON data using JSONPath expressions
    - Support for property access, array operations, wildcards
    - Recursive descent for nested searches
    - Basic filter expressions for conditional selection
    - Quick-access examples for common patterns

- **Base64 Encoder/Decoder**
  - Encode text to Base64 format
  - Decode Base64 strings to readable text
  - Bidirectional conversion with validation
  - Copy/paste integration

- **URL Encoder/Decoder**
  - Encode URLs with proper percent-encoding
  - Decode URL-encoded strings
  - Handle special characters and query parameters
  - Support for complex URL structures

- **Hash Generator**
  - Generate MD5, SHA1, SHA256 hashes
  - Support for text input with real-time generation
  - One-click copy to clipboard for each hash type
  - Multiple hash algorithms simultaneously

- **UUID Generator**
  - Generate Version 4 UUIDs instantly
  - Multiple format options (with/without hyphens, uppercase/lowercase)
  - Bulk generation with customizable count
  - Quick copy individual or all UUIDs

### Coming Soon
- **Regex Tester & Matcher**
- **Color Converter** (hex, RGB, HSL)
- **Timestamp Converter**
- **QR Code Generator**

## 📋 Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

## 🛠️ Installation

### Via Homebrew (Recommended)

#### One-Line Installation
```bash
brew install --cask dilee/tap/zen-dev-toolkit
```

#### Updating to Latest Version
```bash
brew update && brew upgrade --cask zen-dev-toolkit
```

#### Alternative: Tap First Method
```bash
# If you prefer to tap the repository first
brew tap dilee/tap
brew install --cask zen-dev-toolkit
```

### Direct Download

1. Download the latest release from the [Releases page](https://github.com/dilee/zen-dev-toolkit/releases)
2. Unzip the downloaded file
3. Move `ZenDevToolkit.app` to your Applications folder
4. **First launch**: Just double-click to open (fully signed and notarized)

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/dilee/zen-dev-toolkit.git
   cd zen-dev-toolkit
   ```

2. Open the project in Xcode:
   ```bash
   open ZenDevToolkit.xcodeproj
   ```

3. Build and run:
   - Select your Mac as the build target
   - Press ⌘+R or click the Run button in Xcode
   - The app will appear in your menu bar

### Mac App Store
*Coming soon: Planning to release on Mac App Store*

## 💻 Usage

1. **Launch the app**: Look for the toolbox icon (📦) in your menu bar
2. **Open tools**: Left-click the menu bar icon to open the tool popover
3. **Switch tools**: Use the segmented control at the top to switch between utilities
4. **Access menu**: Right-click the menu bar icon for About and Quit options

### Keyboard Shortcuts
- **⌘+C**: Copy selected text
- **⌘+V**: Paste from clipboard
- **⌘+A**: Select all text
- **⌘+Return**: Format JSON (in JSON tool)
- **Click outside**: Close the popover

## 🎨 Features

- **Modern UI**: Clean, minimal design that adapts to macOS light/dark mode
- **Resizable Window**: Adjust the popover size (320×400 to 600×800)
- **Fast & Lightweight**: Native SwiftUI app with instant response times
- **Privacy-Focused**: All processing happens locally, no data sent to servers
- **Pure Menu Bar App**: Runs exclusively in menu bar, won't appear in Dock for clean desktop experience

## 🏗️ Project Structure

```
zen-dev-toolkit/
├── ZenDevToolkit/               # Main app source files
│   ├── ContentView.swift        # Main UI and tool views
│   ├── ZenDevToolkitApp.swift   # App lifecycle and menu bar setup
│   ├── Info.plist               # App configuration
│   └── Assets.xcassets/         # App icons and resources
├── ZenDevToolkitTests/          # Unit tests
├── ZenDevToolkitUITests/        # UI tests
├── ZenDevToolkit.xcodeproj/     # Xcode project file
├── README.md                    # Project documentation
├── .gitignore                   # Git ignore rules
└── CLAUDE.md                    # AI assistant context
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🧪 Testing

Run tests in Xcode:
- **Unit Tests**: ⌘+U
- **UI Tests**: Select `ZenDevToolkitUITests` scheme and run

## 🔧 Troubleshooting

### Homebrew Installation Issues

**Getting an old version?**
```bash
# Force update the tap
brew update --force
brew upgrade --cask zen-dev-toolkit
```

**Want to check installed version?**
```bash
brew list --cask --versions zen-dev-toolkit
```

**Complete reinstall:**
```bash
brew uninstall --cask zen-dev-toolkit
brew install --cask dilee/tap/zen-dev-toolkit
```

### App Won't Open?
- **macOS 14.0+ required**: Check your macOS version in Apple Menu > About This Mac
- **Security warning**: Should not appear (app is fully signed and notarized)
- **Menu bar full**: Look for the 📦 icon, might be hidden in overflow menu

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Dileesha Rajapakse**
- GitHub: [@dilee](https://github.com/dilee)

## Support

If you find this useful, you can [buy me a coffee ☕ on Ko-fi](https://ko-fi.com/dilee).

## Acknowledgments

- Built with SwiftUI and love for the developer community
- Inspired by the need for quick, offline developer utilities
- Special thanks to all contributors and testers

## 📮 Support

If you encounter any issues or have feature requests, please [open an issue](https://github.com/dilee/zen-dev-toolkit/issues).

---
Made with ❤️ for developers who value productivity and simplicity
