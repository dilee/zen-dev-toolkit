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
    @State private var decodedImage: DecodedImage?
    @State private var fullOutputText: String?
    @FocusState private var isInputFocused: Bool

    // TextKit renders each paragraph as a single unit, so an unbroken line beyond
    // a few hundred thousand characters stalls the main thread for seconds every
    // time it draws. Output display is capped; Copy/Save always use the full string.
    static let displayCharacterLimit = 100_000

    static func displayTruncation(of full: String, limit: Int = displayCharacterLimit) -> (display: String, fullIfTruncated: String?) {
        guard full.count > limit else { return (full, nil) }
        return (String(full.prefix(limit)), full)
    }
    
    // File size limits
    private let maxFileSize: Int = 10 * 1024 * 1024 // 10 MB
    private let warningFileSize: Int = 5 * 1024 * 1024 // 5 MB
    
    struct FileInfo {
        let name: String
        let size: Int
        let type: String
        let isBinary: Bool
        var thumbnail: NSImage? = nil

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

    // Holds a successfully decoded image plus the raw bytes it came from.
    struct DecodedImage {
        let image: NSImage
        let data: Data
        let format: ImageFormat
        let pixelWidth: Int
        let pixelHeight: Int
        let byteCount: Int
    }
    
    enum Base64Mode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode and options
            HStack(spacing: 12) {
                Picker("Mode", selection: $mode) {
                    ForEach(Base64Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .onChange(of: mode) {
                    if fileInfo != nil {
                        clearFileInfo()
                    } else if !inputText.isEmpty {
                        processBase64()
                    }
                }

                Spacer()

                Toggle("URL-safe", isOn: $isURLSafe)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .onChange(of: isURLSafe) {
                        if !inputText.isEmpty && fileInfo == nil {
                            processBase64()
                        }
                    }
                    .help("Use URL-safe Base64 encoding (replaces + with -, / with _)")

                Toggle("Line breaks", isOn: $addLineBreaks)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .disabled(mode == .decode)
                    .onChange(of: addLineBreaks) {
                        if !inputText.isEmpty && fileInfo == nil {
                            processBase64()
                        }
                    }
                    .help("Insert a line break every 76 characters (RFC 2045)")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // Input section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(mode == .encode ? "Text to Encode" : "Base64 to Decode")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()
                    
                    // File info badge
                    if let fileInfo = fileInfo {
                        HStack(spacing: 6) {
                            if let thumbnail = fileInfo.thumbnail {
                                Image(nsImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                Image(systemName: fileInfo.isBinary ? "doc.fill" : "doc.text.fill")
                                    .font(.system(size: 10))
                            }
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
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Paste from clipboard")

                    Button(action: loadFromFile) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Load from file")

                    Button(action: clearAll) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .disabled(inputText.isEmpty && outputText.isEmpty && decodedImage == nil)
                    .help("Clear all")
                }
                .padding(.horizontal, 16)
                
                ZStack(alignment: .topLeading) {
                    UndoableTextEditor(text: $inputText) { newText in
                        updateCharacterCount()
                        if !newText.isEmpty && fileInfo == nil {
                            processBase64()
                        } else if newText.isEmpty {
                            outputText = ""
                            outputCharCount = 0
                            decodedImage = nil
                            fullOutputText = nil
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .disabled(isProcessing)
                    
                    if inputText.isEmpty && !isDragging {
                        VStack(spacing: 10) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(Color.secondary.opacity(0.4))
                            Text(mode == .encode ?
                                 "Drop a file here or paste text to encode" :
                                 "Drop a Base64 file or paste to decode")
                                .font(.system(size: 12))
                                .foregroundColor(Color.secondary.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                    }
                    
                    if isDragging {
                        RoundedRectangle(cornerRadius: 8)
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
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isDragging ? Color.accentColor :
                                    (errorMessage.isEmpty ? Color.secondary.opacity(0.15) : Color.red.opacity(0.5)),
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
            
            // Output section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(outputTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    if !errorMessage.isEmpty && !hasOutput {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .symbolRenderingMode(.hierarchical)
                    } else if hasOutput {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                            .symbolRenderingMode(.hierarchical)
                    }

                    Spacer()

                    if let decoded = decodedImage {
                        Button(action: { copyImageToClipboard(decoded.image) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy Image")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy image to clipboard")

                        Button(action: { saveImageToFile(decoded) }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help("Save image to file")
                    } else if !outputText.isEmpty {
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
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help("Save full output to file")

                        Button(action: swapInputOutput) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .disabled(fullOutputText != nil)
                        .help(fullOutputText != nil ? "Swap is unavailable for very large outputs" : "Swap input and output")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if let full = fullOutputText {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("Showing first \(Self.displayCharacterLimit.formatted()) of \(full.count.formatted()) characters — Copy and Save use the full output")
                            .font(.system(size: 10))
                            .lineLimit(2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                }

                ZStack(alignment: .topLeading) {
                    if let decoded = decodedImage {
                        imageResultCard(decoded)
                    } else {
                        UndoableTextEditor(text: fullOutputText != nil ? .constant(outputText) : $outputText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if outputText.isEmpty {
                            Text(mode == .encode ?
                                 "Encoded Base64 will appear here" :
                                 "Decoded text will appear here")
                                .font(.system(size: 12))
                                .foregroundColor(Color.secondary.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    !errorMessage.isEmpty && !hasOutput ?
                                    Color.red.opacity(0.4) : Color.secondary.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 4)
        }
        .onAppear {
            isInputFocused = true
            #if DEBUG
            seedDemoContentIfRequested()
            #endif
        }
    }

    // MARK: - Image Output

    private var hasOutput: Bool {
        !outputText.isEmpty || decodedImage != nil
    }

    private var outputTitle: String {
        if mode == .encode { return "Encoded Base64" }
        return decodedImage != nil ? "Decoded Image" : "Decoded Text"
    }

    private func imageResultCard(_ decoded: DecodedImage) -> some View {
        VStack(spacing: 12) {
            Image(nsImage: decoded.image)
                .resizable()
                .interpolation(.medium)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 140)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.06))
                )

            Text(imageCaption(decoded))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func imageCaption(_ decoded: DecodedImage) -> String {
        var parts = [decoded.format.displayName]
        if decoded.pixelWidth > 0 && decoded.pixelHeight > 0 {
            parts.append("\(decoded.pixelWidth)×\(decoded.pixelHeight)")
        }
        parts.append(formatByteCount(decoded.byteCount))
        return parts.joined(separator: " • ")
    }

    // Reads true pixel dimensions from the decoded representation; (0, 0) when unknown.
    private func pixelDimensions(of image: NSImage) -> (Int, Int) {
        for rep in image.representations where rep.pixelsWide > 0 && rep.pixelsHigh > 0 {
            return (rep.pixelsWide, rep.pixelsHigh)
        }
        return (0, 0)
    }

    private func formatByteCount(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Actions

    #if DEBUG
    // Populates realistic content for marketing captures (`-DemoContent 1`):
    // a gradient image rendered at runtime, delivered as a data URI so the
    // decode path shows the image preview card.
    private func seedDemoContentIfRequested() {
        guard UserDefaults.standard.bool(forKey: "DemoContent") else { return }
        mode = .decode
        let size = NSSize(width: 160, height: 120)
        let image = NSImage(size: size)
        image.lockFocus()
        NSGradient(colors: [.systemBlue, .systemPurple, .systemPink])?
            .draw(in: NSRect(origin: .zero, size: size), angle: 45)
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        inputText = "data:image/png;base64,\(png.base64EncodedString())"
        updateCharacterCount()
        processBase64()
    }
    #endif

    private func processBase64() {
        clearError()
        decodedImage = nil
        fullOutputText = nil

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
        
        setOutput(encoded)
    }

    private func setOutput(_ full: String) {
        let (display, fullIfTruncated) = Self.displayTruncation(of: full)
        outputText = display
        fullOutputText = fullIfTruncated
        outputCharCount = full.count
    }

    private func decodeFromBase64() {
        // Developers routinely paste full "data:image/png;base64,…" URIs, so peel any header first.
        var base64String = stripDataURIPrefix(inputText).trimmingCharacters(in: .whitespacesAndNewlines)

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

        // If the bytes are a recognizable image, present a preview card instead of text.
        if let format = ImageFormat(sniffing: data), let image = NSImage(data: data) {
            let (width, height) = pixelDimensions(of: image)
            decodedImage = DecodedImage(
                image: image,
                data: data,
                format: format,
                pixelWidth: width,
                pixelHeight: height,
                byteCount: data.count
            )
            outputText = ""
            outputCharCount = 0
            return
        }

        guard let decoded = String(data: data, encoding: .utf8) else {
            // Try to handle binary data
            outputText = "Binary data (\(data.count) bytes) - not displayable as text"
            outputCharCount = data.count
            return
        }

        setOutput(decoded)
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
            _ = !textExtensions.contains(fileExtension) && !fileExtension.isEmpty
            
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
                    
                    // Surface a small preview in the badge when the binary is a known image.
                    let thumbnail = ImageFormat(sniffing: data) != nil ? NSImage(data: data) : nil

                    inputText = "[Binary file: \(fileName)]"
                    setOutput(finalEncoded)
                    fileInfo = FileInfo(
                        name: fileName,
                        size: fileSize,
                        type: fileExtension.isEmpty ? "binary" : fileExtension,
                        isBinary: true,
                        thumbnail: thumbnail
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
        decodedImage = nil
        fullOutputText = nil
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
                    try (fullOutputText ?? outputText).write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    showError("Unable to save file: \(error.localizedDescription)")
                }
            }
        }
    }

    private func copyImageToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    private func saveImageToFile(_ decoded: DecodedImage) {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Image"
        savePanel.nameFieldStringValue = "decoded.\(decoded.format.fileExtension)"
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = [decoded.format.utType]

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    // Write the raw decoded bytes verbatim rather than re-encoding the image.
                    try decoded.data.write(to: url)
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
        decodedImage = nil
        fullOutputText = nil
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
        pasteboard.setString(fullOutputText ?? outputText, forType: .string)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        outputText = ""
        outputCharCount = 0
        fullOutputText = nil
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