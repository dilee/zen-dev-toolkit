# ZenDevToolkit

A lightweight macOS menu bar application that provides developers with quick access to commonly-needed utility functions without opening a web browser.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 🚀 Features

### Currently Implemented
- **JSON Formatter & Validator** ✅
  - Format/beautify JSON with proper indentation
  - Minify JSON (remove whitespace)
  - Validate JSON syntax with clear error messages
  - Real-time validation as you type
  - Copy/paste integration with system clipboard
  - Keyboard shortcuts (⌘+Return to format)

### Coming Soon
- **Base64 Encoder/Decoder** 
  - Encode text to Base64
  - Decode Base64 to readable text
  - Support for file processing

- **URL Encoder/Decoder**
  - Encode URLs with proper percent-encoding
  - Decode URL-encoded strings
  - Handle special characters and query parameters

- **Hash Generator**
  - Generate MD5, SHA1, SHA256 hashes
  - Support for text and file input
  - One-click copy to clipboard

- **UUID Generator**
  - Generate Version 4 UUIDs
  - Multiple format options (with/without hyphens)
  - Bulk generation capability

## 📋 Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

## 🛠️ Installation

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
   - The app will appear as a wrench icon in your menu bar

### Direct Download
*Coming soon: Pre-built releases will be available in the Releases section*

### Mac App Store
*Coming soon: Planning to release on Mac App Store for $3.99*

## 💻 Usage

1. **Launch the app**: After building, look for the wrench icon in your menu bar
2. **Open tools**: Left-click the menu bar icon to open the tool popover
3. **Switch tools**: Click the tool buttons at the top to switch between utilities
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
- **Menu Bar Only**: Runs quietly in menu bar without cluttering your Dock

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
