//
//  ContentView.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedTool = "JSON"
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact tool selector without scrolling
            HStack(spacing: 6) {
                CompactToolButton(icon: "curlybraces", title: "JSON", tag: "JSON", selection: $selectedTool)
                CompactToolButton(icon: "abc", title: "Base64", tag: "Base64", selection: $selectedTool)
                CompactToolButton(icon: "link", title: "URL", tag: "URL", selection: $selectedTool)
                CompactToolButton(icon: "number.square", title: "Hash", tag: "Hash", selection: $selectedTool)
                CompactToolButton(icon: "key", title: "UUID", tag: "UUID", selection: $selectedTool)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            
            // Tool content
            Group {
                switch selectedTool {
                case "JSON":
                    JSONFormatterView()
                case "Base64":
                    Base64View()
                case "URL":
                    URLEncoderView()
                case "Hash":
                    HashGeneratorView()
                case "UUID":
                    UUIDGeneratorView()
                default:
                    Text("Select a tool")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 320, idealWidth: 400, maxWidth: 600, 
               minHeight: 400, idealHeight: 500, maxHeight: 800)
    }
}

struct CompactToolButton: View {
    let icon: String
    let title: String
    let tag: String
    @Binding var selection: String
    
    var isSelected: Bool {
        selection == tag
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = tag
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .symbolRenderingMode(.monochrome)
                    .frame(height: 20)
                Text(title)
                    .font(.system(size: 9, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct JSONFormatterView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage = ""
    @State private var isValid = true
    @State private var characterCount = 0
    @State private var lineCount = 0
    @FocusState private var isInputFocused: Bool
    @FocusState private var isOutputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Input section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Input")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !inputText.isEmpty {
                        Text("\(characterCount) chars")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    
                    Button(action: pasteFromClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                            Text("Paste")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Paste from clipboard (⌘V)")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $inputText)
                        .font(.system(size: 12, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .focused($isInputFocused)
                        .onChange(of: inputText) {
                            updateCharacterCount()
                            if !inputText.isEmpty {
                                validateJSON()
                            }
                        }
                    
                    if inputText.isEmpty {
                        Text("Paste or type JSON here...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.secondary.opacity(0.4))
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    errorMessage.isEmpty ? Color.secondary.opacity(0.2) : Color.red.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                )
                .frame(minHeight: 120, idealHeight: 150, maxHeight: 200)
                .padding(.horizontal, 16)
            }
            
            // Error message with modern design
            if !errorMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .symbolRenderingMode(.multicolor)
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // Modern action buttons
            HStack(spacing: 10) {
                Button(action: formatJSON) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 12))
                        Text("Format")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(inputText.isEmpty ? Color.accentColor.opacity(0.3) : Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                
                Button(action: minifyJSON) {
                    HStack {
                        Image(systemName: "minus.rectangle")
                            .font(.system(size: 12))
                        Text("Minify")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
                
                Button(action: clearAll) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty && outputText.isEmpty)
                .help("Clear all")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Output section with modern design
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Output")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if isValid && !outputText.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    Spacer()
                    
                    if !outputText.isEmpty {
                        Text("\(lineCount) lines")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                        
                        Button(action: copyToClipboard) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy to clipboard (⌘C)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        Text(outputText)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .textSelection(.enabled)
                    }
                    
                    if outputText.isEmpty {
                        Text("Formatted JSON will appear here...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.secondary.opacity(0.4))
                            .padding(12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isValid && !outputText.isEmpty ? Color.green.opacity(0.4) : Color.secondary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Focus the input field when view appears
            isInputFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification)) { _ in
            // This ensures the app responds to system events
        }
    }
    
    // MARK: - Actions
    
    private func formatJSON() {
        clearError()
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter some JSON to format")
            return
        }
        
        do {
            let data = inputText.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            
            if let formattedString = String(data: formattedData, encoding: .utf8) {
                outputText = formattedString
                isValid = true
                updateLineCount()
            } else {
                showError("Could not format JSON")
            }
        } catch {
            let errorDescription = extractErrorDescription(from: error)
            showError(errorDescription)
            isValid = false
        }
    }
    
    private func minifyJSON() {
        clearError()
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter some JSON to minify")
            return
        }
        
        do {
            let data = inputText.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let minifiedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
            
            if let minifiedString = String(data: minifiedData, encoding: .utf8) {
                outputText = minifiedString
                isValid = true
                updateLineCount()
            } else {
                showError("Could not minify JSON")
            }
        } catch {
            let errorDescription = extractErrorDescription(from: error)
            showError(errorDescription)
            isValid = false
        }
    }
    
    private func validateJSON() {
        clearError()
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        do {
            let data = inputText.data(using: .utf8) ?? Data()
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            isValid = true
        } catch {
            let errorDescription = extractErrorDescription(from: error)
            showError(errorDescription)
            isValid = false
        }
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
        characterCount = 0
        lineCount = 0
        clearError()
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            inputText = string
            updateCharacterCount()
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputText, forType: .string)
        
        // Visual feedback could be added here
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        outputText = ""
        lineCount = 0
    }
    
    private func clearError() {
        errorMessage = ""
    }
    
    private func updateCharacterCount() {
        characterCount = inputText.count
    }
    
    private func updateLineCount() {
        lineCount = outputText.components(separatedBy: .newlines).count
    }
    
    private func extractErrorDescription(from error: Error) -> String {
        let nsError = error as NSError
        
        if let debugDescription = nsError.userInfo["NSDebugDescription"] as? String {
            // Parse the debug description for more readable error
            if debugDescription.contains("character") {
                let components = debugDescription.components(separatedBy: "character ")
                if components.count > 1 {
                    let charInfo = components[1].components(separatedBy: ".")
                    if let charNumber = charInfo.first {
                        return "Invalid JSON at character \(charNumber)"
                    }
                }
            }
            return debugDescription
        }
        
        return "Invalid JSON format"
    }
}

struct Base64View: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage = ""
    @State private var mode: Base64Mode = .encode
    @State private var isURLSafe = false
    @State private var addLineBreaks = false
    @State private var characterCount = 0
    @State private var outputCharCount = 0
    @State private var isProcessing = false
    @State private var isDragging = false
    @State private var fileInfo: FileInfo?
    @FocusState private var isInputFocused: Bool
    
    // File size limits
    private let maxFileSize: Int = 10 * 1024 * 1024 // 10 MB
    private let warningFileSize: Int = 5 * 1024 * 1024 // 5 MB
    
    struct FileInfo {
        let name: String
        let size: Int
        let type: String
        let isBinary: Bool
        
        var formattedSize: String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useBytes, .useKB, .useMB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(size))
        }
        
        var displayName: String {
            if name.count > 30 {
                let start = name.prefix(15)
                let end = name.suffix(12)
                return "\(start)...\(end)"
            }
            return name
        }
    }
    
    enum Base64Mode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
        
        var icon: String {
            switch self {
            case .encode: return "arrow.right.square"
            case .decode: return "arrow.left.square"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode selector and options
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(Base64Mode.allCases, id: \.self) { currentMode in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                mode = currentMode
                                // Auto-process if there's input
                                if !inputText.isEmpty {
                                    processBase64()
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: currentMode.icon)
                                    .font(.system(size: 12))
                                Text(currentMode.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(mode == currentMode ? Color.accentColor : Color.secondary.opacity(0.1))
                            )
                            .foregroundColor(mode == currentMode ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Options
                HStack(spacing: 16) {
                    Toggle(isOn: $isURLSafe) {
                        HStack(spacing: 4) {
                            Image(systemName: "link.circle")
                                .font(.system(size: 11))
                            Text("URL Safe")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .toggleStyle(.checkbox)
                    .onChange(of: isURLSafe) { _ in
                        if !inputText.isEmpty {
                            processBase64()
                        }
                    }
                    .help("Use URL-safe Base64 encoding (replaces + with -, / with _)")
                    
                    if mode == .encode {
                        Toggle(isOn: $addLineBreaks) {
                            HStack(spacing: 4) {
                                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                                    .font(.system(size: 11))
                                Text("Line Breaks")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .toggleStyle(.checkbox)
                        .onChange(of: addLineBreaks) { _ in
                            if !inputText.isEmpty {
                                processBase64()
                            }
                        }
                        .help("Add line breaks every 76 characters (RFC 2045)")
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Input section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(mode == .encode ? "Text to Encode" : "Base64 to Decode")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // File info badge
                    if let fileInfo = fileInfo {
                        HStack(spacing: 6) {
                            Image(systemName: fileInfo.isBinary ? "doc.fill" : "doc.text.fill")
                                .font(.system(size: 10))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(fileInfo.displayName)
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                                Text(fileInfo.formattedSize)
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                            Button(action: { clearFileInfo() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(fileInfo.isBinary ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(fileInfo.isBinary ? Color.orange.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    } else if !inputText.isEmpty {
                        Text("\(characterCount) chars")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    
                    Button(action: pasteFromClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                            Text("Paste")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Paste from clipboard (⌘V)")
                    
                    Button(action: loadFromFile) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 11))
                            Text("File")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Load from file")
                }
                .padding(.horizontal, 16)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $inputText)
                        .font(.system(size: 12, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .focused($isInputFocused)
                        .disabled(isProcessing)
                        .onChange(of: inputText) {
                            updateCharacterCount()
                            if !inputText.isEmpty && fileInfo == nil {
                                processBase64()
                            } else if inputText.isEmpty {
                                outputText = ""
                                outputCharCount = 0
                            }
                        }
                    
                    if inputText.isEmpty && !isDragging {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.badge.arrow.down")
                                .font(.system(size: 32))
                                .foregroundColor(Color.secondary.opacity(0.3))
                            Text(mode == .encode ? 
                                 "Drop a file here or paste text to encode" : 
                                 "Drop a Base64 file or paste to decode")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                    }
                    
                    if isDragging {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.1))
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.accentColor)
                                    Text("Drop file to \(mode.rawValue.lowercased())")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.accentColor)
                                }
                            )
                    }
                    
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isDragging ? Color.accentColor : 
                                    (errorMessage.isEmpty ? Color.secondary.opacity(0.2) : Color.red.opacity(0.5)),
                                    lineWidth: isDragging ? 2 : 1
                                )
                        )
                )
                .onDrop(of: [.fileURL, .data], isTargeted: $isDragging) { providers in
                    handleDrop(providers: providers)
                    return true
                }
                .frame(minHeight: 120, idealHeight: 150, maxHeight: 200)
                .padding(.horizontal, 16)
            }
            
            // Error message
            if !errorMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .symbolRenderingMode(.multicolor)
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button(action: processBase64) {
                    HStack {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(inputText.isEmpty ? Color.accentColor.opacity(0.3) : Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                
                Button(action: swapInputOutput) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12))
                        Text("Swap")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .disabled(outputText.isEmpty)
                .help("Swap input and output")
                
                Button(action: clearAll) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty && outputText.isEmpty)
                .help("Clear all")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Output section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(mode == .encode ? "Encoded Base64" : "Decoded Text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if !errorMessage.isEmpty && outputText.isEmpty {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .symbolRenderingMode(.hierarchical)
                    } else if !outputText.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    Spacer()
                    
                    if !outputText.isEmpty {
                        Text("\(outputCharCount) chars")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                        
                        Button(action: copyToClipboard) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy to clipboard (⌘C)")
                        
                        Button(action: saveToFile) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 11))
                                Text("Save")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Save to file")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        Text(outputText)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .textSelection(.enabled)
                    }
                    
                    if outputText.isEmpty {
                        Text(mode == .encode ? 
                             "Encoded Base64 will appear here..." : 
                             "Decoded text will appear here...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.secondary.opacity(0.4))
                            .padding(12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    !errorMessage.isEmpty && outputText.isEmpty ? 
                                    Color.red.opacity(0.4) : 
                                    (!outputText.isEmpty ? Color.green.opacity(0.4) : Color.secondary.opacity(0.2)),
                                    lineWidth: 1
                                )
                        )
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isInputFocused = true
        }
    }
    
    // MARK: - Actions
    
    private func processBase64() {
        clearError()
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            outputText = ""
            outputCharCount = 0
            return
        }
        
        if mode == .encode {
            encodeToBase64()
        } else {
            decodeFromBase64()
        }
    }
    
    private func encodeToBase64() {
        guard let data = inputText.data(using: .utf8) else {
            showError("Unable to encode text")
            return
        }
        
        var encoded = data.base64EncodedString(options: addLineBreaks ? [.lineLength76Characters, .endLineWithLineFeed] : [])
        
        if isURLSafe {
            encoded = encoded
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        
        outputText = encoded
        outputCharCount = encoded.count
    }
    
    private func decodeFromBase64() {
        var base64String = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any whitespace or newlines within the base64 string
        base64String = base64String.replacingOccurrences(of: "\n", with: "")
        base64String = base64String.replacingOccurrences(of: "\r", with: "")
        base64String = base64String.replacingOccurrences(of: " ", with: "")
        
        if isURLSafe {
            // Convert URL-safe base64 back to standard base64
            base64String = base64String
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            
            // Add padding if necessary
            let remainder = base64String.count % 4
            if remainder > 0 {
                base64String += String(repeating: "=", count: 4 - remainder)
            }
        }
        
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            showError("Invalid Base64 format")
            return
        }
        
        guard let decoded = String(data: data, encoding: .utf8) else {
            // Try to handle binary data
            outputText = "Binary data (\(data.count) bytes) - not displayable as text"
            outputCharCount = data.count
            return
        }
        
        outputText = decoded
        outputCharCount = decoded.count
    }
    
    private func swapInputOutput() {
        let temp = inputText
        inputText = outputText
        outputText = temp
        
        // Toggle mode
        mode = (mode == .encode) ? .decode : .encode
        
        // Clear error and update counts
        clearError()
        updateCharacterCount()
        outputCharCount = outputText.count
    }
    
    private func loadFromFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = mode == .encode ? "Choose a file to encode" : "Choose a Base64 file to decode"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        
        if mode == .decode {
            openPanel.allowedContentTypes = [.text, .plainText, .utf8PlainText]
        } else {
            // Allow all file types for encoding
            openPanel.allowedContentTypes = []
        }
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                processFile(at: url)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                self.processFile(at: url)
            }
        }
    }
    
    private func processFile(at url: URL) {
        isProcessing = true
        clearError()
        
        // Check file size first
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int ?? 0
            
            if fileSize > maxFileSize {
                showError("File too large. Maximum size is 10 MB")
                isProcessing = false
                return
            }
            
            if fileSize > warningFileSize {
                // Could show a warning but proceed
            }
            
            let fileName = url.lastPathComponent
            let fileExtension = url.pathExtension.lowercased()
            
            // Determine if file is likely binary
            let textExtensions = ["txt", "json", "xml", "csv", "md", "yml", "yaml", "html", "css", "js", "ts", "swift", "py", "java", "c", "cpp", "h", "m", "rb", "go", "rs", "php", "sql", "sh", "bash"]
            let isBinary = !textExtensions.contains(fileExtension) && !fileExtension.isEmpty
            
            if mode == .encode {
                // Try to read as text first
                if let content = try? String(contentsOf: url, encoding: .utf8) {
                    // It's a text file
                    inputText = content
                    fileInfo = FileInfo(
                        name: fileName,
                        size: fileSize,
                        type: fileExtension.isEmpty ? "text" : fileExtension,
                        isBinary: false
                    )
                    updateCharacterCount()
                    processBase64()
                } else {
                    // It's a binary file
                    let data = try Data(contentsOf: url)
                    let encoded = data.base64EncodedString(options: addLineBreaks ? [.lineLength76Characters, .endLineWithLineFeed] : [])
                    
                    var finalEncoded = encoded
                    if isURLSafe {
                        finalEncoded = encoded
                            .replacingOccurrences(of: "+", with: "-")
                            .replacingOccurrences(of: "/", with: "_")
                            .replacingOccurrences(of: "=", with: "")
                    }
                    
                    inputText = "[Binary file: \(fileName)]"
                    outputText = finalEncoded
                    outputCharCount = finalEncoded.count
                    fileInfo = FileInfo(
                        name: fileName,
                        size: fileSize,
                        type: fileExtension.isEmpty ? "binary" : fileExtension,
                        isBinary: true
                    )
                    characterCount = data.count
                }
            } else {
                // For decoding, always expect text file with Base64 content
                if let content = try? String(contentsOf: url, encoding: .utf8) {
                    inputText = content
                    fileInfo = FileInfo(
                        name: fileName,
                        size: fileSize,
                        type: fileExtension.isEmpty ? "base64" : fileExtension,
                        isBinary: false
                    )
                    updateCharacterCount()
                    processBase64()
                } else {
                    showError("Unable to read Base64 file. Please ensure it's a text file.")
                }
            }
        } catch {
            showError("Unable to read file: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    private func clearFileInfo() {
        fileInfo = nil
        inputText = ""
        outputText = ""
        characterCount = 0
        outputCharCount = 0
        clearError()
    }
    
    private func saveToFile() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Base64 Output"
        savePanel.nameFieldStringValue = mode == .encode ? "encoded.txt" : "decoded.txt"
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = [.plainText]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try outputText.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    showError("Unable to save file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
        characterCount = 0
        outputCharCount = 0
        fileInfo = nil
        clearError()
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            fileInfo = nil  // Clear file info when pasting text
            inputText = string
            updateCharacterCount()
            processBase64()
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputText, forType: .string)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        outputText = ""
        outputCharCount = 0
    }
    
    private func clearError() {
        errorMessage = ""
    }
    
    private func updateCharacterCount() {
        characterCount = inputText.count
    }
}

struct URLEncoderView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage = ""
    @State private var mode: URLMode = .encode
    @State private var encodeMode: EncodeMode = .standard
    @State private var characterCount = 0
    @State private var outputCharCount = 0
    @State private var parsedParams: [(key: String, value: String)] = []
    @State private var urlComponents: URLAnalysis?
    @State private var showURLAnalysis = false
    @FocusState private var isInputFocused: Bool
    
    enum URLMode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
        case analyze = "Analyze"
        
        var icon: String {
            switch self {
            case .encode: return "arrow.right.square"
            case .decode: return "arrow.left.square"
            case .analyze: return "magnifyingglass"
            }
        }
    }
    
    enum EncodeMode: String, CaseIterable {
        case standard = "Standard"
        case component = "Component"
        case formData = "Form Data"
        
        var description: String {
            switch self {
            case .standard: return "Full URL encoding"
            case .component: return "URL component encoding"
            case .formData: return "Form/query parameter encoding"
            }
        }
    }
    
    struct URLAnalysis {
        let scheme: String?
        let host: String?
        let port: Int?
        let path: String
        let query: String?
        let fragment: String?
        let user: String?
        let password: String?
        let queryItems: [(key: String, value: String)]
        let isValid: Bool
        
        var displayPort: String {
            if let port = port {
                return ":\(port)"
            }
            return ""
        }
        
        var baseURL: String {
            var result = ""
            if let scheme = scheme {
                result += "\(scheme)://"
            }
            if let user = user {
                result += user
                if let password = password {
                    result += ":\(password)"
                }
                result += "@"
            }
            if let host = host {
                result += host
            }
            result += displayPort
            result += path
            return result
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode selector
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(URLMode.allCases, id: \.self) { currentMode in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                mode = currentMode
                                if !inputText.isEmpty {
                                    processURL()
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: currentMode.icon)
                                    .font(.system(size: 12))
                                Text(currentMode.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(mode == currentMode ? Color.accentColor : Color.secondary.opacity(0.1))
                            )
                            .foregroundColor(mode == currentMode ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Encoding options (only for encode mode)
                if mode == .encode {
                    HStack(spacing: 12) {
                        ForEach(EncodeMode.allCases, id: \.self) { currentEncodeMode in
                            Button(action: {
                                encodeMode = currentEncodeMode
                                if !inputText.isEmpty {
                                    processURL()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text(currentEncodeMode.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                    Text(currentEncodeMode.description)
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(encodeMode == currentEncodeMode ? 
                                              Color.blue.opacity(0.2) : Color.secondary.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(
                                                    encodeMode == currentEncodeMode ? 
                                                    Color.blue.opacity(0.5) : Color.clear,
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Input section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(mode == .encode ? "Text to Encode" : (mode == .decode ? "URL to Decode" : "URL to Analyze"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !inputText.isEmpty {
                        Text("\(characterCount) chars")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    
                    Button(action: pasteFromClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                            Text("Paste")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Paste from clipboard (⌘V)")
                }
                .padding(.horizontal, 16)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $inputText)
                        .font(.system(size: 12, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .focused($isInputFocused)
                        .onChange(of: inputText) {
                            updateCharacterCount()
                            if !inputText.isEmpty {
                                processURL()
                            } else {
                                outputText = ""
                                outputCharCount = 0
                                parsedParams = []
                                urlComponents = nil
                            }
                        }
                    
                    if inputText.isEmpty {
                        Text(mode == .encode ? 
                             "Paste or type text/URL to encode..." : 
                             (mode == .decode ? "Paste encoded URL to decode..." : "Paste URL to analyze..."))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.secondary.opacity(0.4))
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    errorMessage.isEmpty ? Color.secondary.opacity(0.2) : Color.red.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                )
                .frame(minHeight: 100, idealHeight: 120, maxHeight: 150)
                .padding(.horizontal, 16)
            }
            
            // Error message
            if !errorMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .symbolRenderingMode(.multicolor)
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button(action: processURL) {
                    HStack {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(inputText.isEmpty ? Color.accentColor.opacity(0.3) : Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                
                if mode != .analyze {
                    Button(action: swapInputOutput) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 12))
                            Text("Swap")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(outputText.isEmpty)
                    .help("Swap input and output")
                }
                
                if !parsedParams.isEmpty && mode == .analyze {
                    Button(action: buildURLFromParams) {
                        HStack {
                            Image(systemName: "hammer")
                                .font(.system(size: 12))
                            Text("Build")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .help("Build URL from parameters")
                }
                
                Button(action: clearAll) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty && outputText.isEmpty)
                .help("Clear all")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Output section
            if mode == .analyze && urlComponents != nil {
                // URL Analysis View
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // URL Components
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("URL Components")
                                    .font(.system(size: 12, weight: .semibold))
                                
                                Spacer()
                                
                                if urlComponents?.isValid == true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.green)
                                        .symbolRenderingMode(.hierarchical)
                                }
                                
                                Button(action: copyComponentsToClipboard) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 11))
                                        Text("Copy")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if let scheme = urlComponents?.scheme {
                                    ComponentRow(label: "Scheme", value: scheme, color: .blue)
                                }
                                if let host = urlComponents?.host {
                                    ComponentRow(label: "Host", value: host, color: .green)
                                }
                                if let port = urlComponents?.port {
                                    ComponentRow(label: "Port", value: String(port), color: .orange)
                                }
                                if let user = urlComponents?.user {
                                    ComponentRow(label: "User", value: user, color: .purple)
                                }
                                if let password = urlComponents?.password {
                                    ComponentRow(label: "Password", value: String(repeating: "•", count: password.count), color: .red)
                                }
                                ComponentRow(label: "Path", value: urlComponents?.path ?? "/", color: .indigo)
                                if let query = urlComponents?.query {
                                    ComponentRow(label: "Query", value: query, color: .teal)
                                }
                                if let fragment = urlComponents?.fragment {
                                    ComponentRow(label: "Fragment", value: fragment, color: .pink)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                        }
                        
                        // Query Parameters
                        if !parsedParams.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Query Parameters (\(parsedParams.count))")
                                        .font(.system(size: 12, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    Button(action: copyParamsAsJSON) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 11))
                                            Text("Copy as JSON")
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.accentColor)
                                    .help("Copy query parameters as JSON object")
                                }
                                
                                VStack(spacing: 4) {
                                    ForEach(Array(parsedParams.enumerated()), id: \.offset) { index, param in
                                        HStack {
                                            Text(param.key)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.blue)
                                                .textSelection(.enabled)
                                            
                                            Text("=")
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.secondary)
                                            
                                            Text(param.value)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.primary)
                                                .textSelection(.enabled)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(index % 2 == 0 ? 
                                                      Color(NSColor.controlBackgroundColor) : 
                                                      Color.secondary.opacity(0.05))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Regular output section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(mode == .encode ? "Encoded URL" : "Decoded Text")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if !outputText.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                                .symbolRenderingMode(.hierarchical)
                        }
                        
                        Spacer()
                        
                        if !outputText.isEmpty {
                            Text("\(outputCharCount) chars")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.1)))
                            
                            Button(action: copyToClipboard) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                    Text("Copy")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                            .help("Copy to clipboard (⌘C)")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    ZStack(alignment: .topLeading) {
                        ScrollView {
                            Text(outputText)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .textSelection(.enabled)
                        }
                        
                        if outputText.isEmpty {
                            Text(mode == .encode ? 
                                 "Encoded URL will appear here..." : 
                                 "Decoded text will appear here...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.4))
                                .padding(12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        !outputText.isEmpty ? Color.green.opacity(0.4) : Color.secondary.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isInputFocused = true
        }
    }
    
    // MARK: - Actions
    
    private func processURL() {
        clearError()
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            outputText = ""
            outputCharCount = 0
            parsedParams = []
            urlComponents = nil
            return
        }
        
        switch mode {
        case .encode:
            encodeURL()
        case .decode:
            decodeURL()
        case .analyze:
            analyzeURL()
        }
    }
    
    private func encodeURL() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch encodeMode {
        case .standard:
            // Full URL encoding
            if let encoded = trimmedInput.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                outputText = encoded
                outputCharCount = encoded.count
            } else {
                showError("Unable to encode URL")
            }
            
        case .component:
            // Component encoding (more aggressive)
            let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
            if let encoded = trimmedInput.addingPercentEncoding(withAllowedCharacters: allowedCharacters) {
                outputText = encoded
                outputCharCount = encoded.count
            } else {
                showError("Unable to encode component")
            }
            
        case .formData:
            // Form data encoding (space becomes +)
            let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "*-._"))
            if let encoded = trimmedInput.addingPercentEncoding(withAllowedCharacters: allowedCharacters) {
                let formEncoded = encoded.replacingOccurrences(of: "%20", with: "+")
                outputText = formEncoded
                outputCharCount = formEncoded.count
            } else {
                showError("Unable to encode form data")
            }
        }
    }
    
    private func decodeURL() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle form data (+ to space) first
        let preprocessed = trimmedInput.replacingOccurrences(of: "+", with: " ")
        
        if let decoded = preprocessed.removingPercentEncoding {
            outputText = decoded
            outputCharCount = decoded.count
        } else {
            showError("Invalid URL encoding")
        }
    }
    
    private func analyzeURL() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: trimmedInput) else {
            showError("Invalid URL format")
            return
        }
        
        var queryItems: [(key: String, value: String)] = []
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let items = components.queryItems {
                queryItems = items.map { ($0.name, $0.value ?? "") }
            }
            
            urlComponents = URLAnalysis(
                scheme: components.scheme,
                host: components.host,
                port: components.port,
                path: components.path.isEmpty ? "/" : components.path,
                query: components.query,
                fragment: components.fragment,
                user: components.user,
                password: components.password,
                queryItems: queryItems,
                isValid: true
            )
            
            parsedParams = queryItems
            
            // Create formatted output
            var analysisOutput = "URL Analysis:\n\n"
            
            if let scheme = components.scheme {
                analysisOutput += "Scheme: \(scheme)\n"
            }
            if let host = components.host {
                analysisOutput += "Host: \(host)\n"
            }
            if let port = components.port {
                analysisOutput += "Port: \(port)\n"
            }
            analysisOutput += "Path: \(components.path.isEmpty ? "/" : components.path)\n"
            
            if !queryItems.isEmpty {
                analysisOutput += "\nQuery Parameters:\n"
                for item in queryItems {
                    analysisOutput += "  \(item.key) = \(item.value)\n"
                }
            }
            
            if let fragment = components.fragment {
                analysisOutput += "\nFragment: \(fragment)\n"
            }
            
            outputText = analysisOutput
            outputCharCount = analysisOutput.count
        } else {
            showError("Unable to parse URL")
        }
    }
    
    private func buildURLFromParams() {
        guard let components = urlComponents else { return }
        
        var urlString = components.baseURL
        
        if !parsedParams.isEmpty {
            let queryString = parsedParams
                .map { key, value in
                    let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                    let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                    return "\(encodedKey)=\(encodedValue)"
                }
                .joined(separator: "&")
            
            urlString += "?" + queryString
        }
        
        if let fragment = components.fragment {
            urlString += "#" + fragment
        }
        
        outputText = urlString
        outputCharCount = urlString.count
    }
    
    private func swapInputOutput() {
        let temp = inputText
        inputText = outputText
        outputText = temp
        
        // Toggle mode
        mode = (mode == .encode) ? .decode : .encode
        
        // Clear error and update counts
        clearError()
        updateCharacterCount()
        outputCharCount = outputText.count
    }
    
    private func copyComponentsToClipboard() {
        guard let components = urlComponents else { return }
        
        var text = "URL Components:\n"
        if let scheme = components.scheme {
            text += "Scheme: \(scheme)\n"
        }
        if let host = components.host {
            text += "Host: \(host)\n"
        }
        if let port = components.port {
            text += "Port: \(port)\n"
        }
        text += "Path: \(components.path)\n"
        if let query = components.query {
            text += "Query: \(query)\n"
        }
        if let fragment = components.fragment {
            text += "Fragment: \(fragment)\n"
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func copyParamsAsJSON() {
        // Group parameters by key to handle duplicates (like array parameters)
        var groupedParams: [String: Any] = [:]
        
        for (key, value) in parsedParams {
            if let existingValue = groupedParams[key] {
                // Key already exists, convert to array or append to existing array
                if var array = existingValue as? [String] {
                    array.append(value)
                    groupedParams[key] = array
                } else if let string = existingValue as? String {
                    groupedParams[key] = [string, value]
                }
            } else {
                // Check if this looks like an array parameter (ends with [])
                if key.hasSuffix("[]") {
                    // Start as array even for single value
                    groupedParams[key] = [value]
                } else {
                    groupedParams[key] = value
                }
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: groupedParams, options: [.prettyPrinted, .sortedKeys])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(jsonString, forType: .string)
            }
        } catch {
            showError("Unable to convert to JSON")
        }
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
        characterCount = 0
        outputCharCount = 0
        parsedParams = []
        urlComponents = nil
        clearError()
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            inputText = string
            updateCharacterCount()
            processURL()
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputText, forType: .string)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        outputText = ""
        outputCharCount = 0
        parsedParams = []
        urlComponents = nil
    }
    
    private func clearError() {
        errorMessage = ""
    }
    
    private func updateCharacterCount() {
        characterCount = inputText.count
    }
}

struct ComponentRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(color)
                .textSelection(.enabled)
                .lineLimit(1)
            
            Spacer()
        }
    }
}

// HashGeneratorView is imported from its own file
// UUIDGeneratorView is imported from its own file

#Preview {
    ContentView()
}
