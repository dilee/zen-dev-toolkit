//
//  Base64View.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI
import UniformTypeIdentifiers

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

#Preview {
    Base64View()
        .frame(width: 400, height: 500)
}