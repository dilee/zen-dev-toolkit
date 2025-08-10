import SwiftUI
import CryptoKit
import CommonCrypto

struct HashGeneratorView: View {
    @State private var inputText = ""
    @State private var secretKey = ""
    @State private var compareHash = ""
    @State private var selectedAlgorithm = HashAlgorithm.sha256
    @State private var hashOutput = ""
    @State private var isHMAC = false
    @State private var isUppercase = false
    @State private var selectedFileURL: URL?
    @State private var isProcessing = false
    @State private var comparisonResult: ComparisonResult = .none
    @State private var characterCount = 0
    @State private var outputCharCount = 0
    @FocusState private var isInputFocused: Bool
    
    enum HashAlgorithm: String, CaseIterable {
        case md5 = "MD5"
        case sha1 = "SHA-1"
        case sha256 = "SHA-256"
        case sha384 = "SHA-384"
        case sha512 = "SHA-512"
        
        var displayName: String { rawValue }
    }
    
    enum ComparisonResult {
        case none, match, noMatch
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Algorithm and options section
            VStack(spacing: 12) {
                // Algorithm Selection
                HStack(spacing: 8) {
                    ForEach(HashAlgorithm.allCases, id: \.self) { algorithm in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedAlgorithm = algorithm
                                generateHash()
                            }
                        }) {
                            Text(algorithm.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedAlgorithm == algorithm ? Color.accentColor : Color.secondary.opacity(0.1))
                                )
                                .foregroundColor(selectedAlgorithm == algorithm ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Options
                HStack(spacing: 16) {
                    Toggle(isOn: $isHMAC) {
                        HStack(spacing: 4) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 11))
                            Text("HMAC")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .toggleStyle(.checkbox)
                    .onChange(of: isHMAC) { _, _ in
                        generateHash()
                    }
                    
                    Toggle(isOn: $isUppercase) {
                        HStack(spacing: 4) {
                            Image(systemName: "textformat")
                                .font(.system(size: 11))
                            Text("Uppercase")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .toggleStyle(.checkbox)
                    .onChange(of: isUppercase) { _, _ in
                        generateHash()
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // HMAC Secret Key (shown only when HMAC is enabled)
            if isHMAC {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Secret Key")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $secretKey)
                            .font(.system(size: 12, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .onChange(of: secretKey) { _, _ in
                                generateHash()
                            }
                        
                        if secretKey.isEmpty {
                            Text("Enter secret key for HMAC...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.4))
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .frame(height: 50)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            // Input section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Input Text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedFileURL != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 10))
                            Text(selectedFileURL!.lastPathComponent)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Button(action: { 
                                selectedFileURL = nil
                                generateHash()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                        )
                    } else if !inputText.isEmpty {
                        Text("\(characterCount) chars")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    
                    Button(action: pasteInput) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                            Text("Paste")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Paste from clipboard")
                    
                    Button(action: selectFile) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 11))
                            Text("File")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Hash a file")
                }
                .padding(.horizontal, 16)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $inputText)
                        .font(.system(size: 12, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .focused($isInputFocused)
                        .disabled(selectedFileURL != nil)
                        .onChange(of: inputText) { _, _ in
                            updateCharacterCount()
                            if selectedFileURL == nil {
                                generateHash()
                            }
                        }
                    
                    if inputText.isEmpty && selectedFileURL == nil {
                        Text("Paste or type text to hash...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.secondary.opacity(0.4))
                            .padding(12)
                            .allowsHitTesting(false)
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
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
                .frame(minHeight: 80, idealHeight: 100, maxHeight: 120)
                .padding(.horizontal, 16)
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button(action: generateHash) {
                    HStack {
                        Image(systemName: "number.square")
                            .font(.system(size: 12))
                        Text("Generate Hash")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(inputText.isEmpty && selectedFileURL == nil ? Color.accentColor.opacity(0.3) : Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty && selectedFileURL == nil)
                .keyboardShortcut(.return, modifiers: .command)
                
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
                .disabled(inputText.isEmpty && hashOutput.isEmpty && selectedFileURL == nil)
                .help("Clear all")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Hash Output section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Hash Output")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if !hashOutput.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    Spacer()
                    
                    if !hashOutput.isEmpty {
                        Text("\(outputCharCount) chars")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                        
                        Button(action: copyOutput) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy hash to clipboard")
                    }
                }
                .padding(.horizontal, 16)
                
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        Text(hashOutput)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .textSelection(.enabled)
                    }
                    
                    if hashOutput.isEmpty {
                        Text("Hash will appear here...")
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
                                    !hashOutput.isEmpty ? Color.green.opacity(0.4) : Color.secondary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
                .frame(minHeight: 60, idealHeight: 80)
                .padding(.horizontal, 16)
            }
            
            // Hash Comparison section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Compare Hash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if comparisonResult == .match {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 11))
                            Text("Match")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else if comparisonResult == .noMatch {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 11))
                            Text("No Match")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: pasteCompareHash) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                            Text("Paste")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Paste hash to compare")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                TextField("Paste hash to compare", text: $compareHash)
                    .font(.system(size: 12, design: .monospaced))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: compareHash) { _, _ in
                        performComparison()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            
            Spacer()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isInputFocused = true
        }
    }
    
    // MARK: - Hash Generation
    
    private func generateHash() {
        guard !inputText.isEmpty || selectedFileURL != nil else {
            hashOutput = ""
            outputCharCount = 0
            return
        }
        
        if let fileURL = selectedFileURL {
            generateFileHash(url: fileURL)
        } else {
            let data = inputText.data(using: .utf8) ?? Data()
            
            if isHMAC {
                hashOutput = generateHMAC(data: data, key: secretKey)
            } else {
                hashOutput = generateRegularHash(data: data)
            }
            
            if isUppercase {
                hashOutput = hashOutput.uppercased()
            }
            
            outputCharCount = hashOutput.count
        }
        
        performComparison()
    }
    
    private func generateRegularHash(data: Data) -> String {
        switch selectedAlgorithm {
        case .md5:
            return Insecure.MD5.hash(data: data).hexString
        case .sha1:
            return Insecure.SHA1.hash(data: data).hexString
        case .sha256:
            return SHA256.hash(data: data).hexString
        case .sha384:
            return SHA384.hash(data: data).hexString
        case .sha512:
            return SHA512.hash(data: data).hexString
        }
    }
    
    private func generateHMAC(data: Data, key: String) -> String {
        let keyData = key.data(using: .utf8) ?? Data()
        
        switch selectedAlgorithm {
        case .md5:
            return hmacMD5(data: data, key: keyData)
        case .sha1:
            return hmacSHA1(data: data, key: keyData)
        case .sha256:
            let hmac = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: keyData))
            return Data(hmac).hexString
        case .sha384:
            let hmac = HMAC<SHA384>.authenticationCode(for: data, using: SymmetricKey(data: keyData))
            return Data(hmac).hexString
        case .sha512:
            let hmac = HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: keyData))
            return Data(hmac).hexString
        }
    }
    
    // MARK: - CommonCrypto HMAC Functions
    
    private func hmacMD5(data: Data, key: Data) -> String {
        var hmac = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgMD5),
                       keyBytes.baseAddress, key.count,
                       dataBytes.baseAddress, data.count,
                       &hmac)
            }
        }
        return Data(hmac).hexString
    }
    
    private func hmacSHA1(data: Data, key: Data) -> String {
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
                       keyBytes.baseAddress, key.count,
                       dataBytes.baseAddress, data.count,
                       &hmac)
            }
        }
        return Data(hmac).hexString
    }
    
    // MARK: - File Hashing
    
    private func generateFileHash(url: URL) {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    self.hashOutput = "Error reading file"
                    self.outputCharCount = 0
                    self.isProcessing = false
                }
                return
            }
            
            let hash: String
            if self.isHMAC {
                hash = self.generateHMAC(data: data, key: self.secretKey)
            } else {
                hash = self.generateRegularHash(data: data)
            }
            
            DispatchQueue.main.async {
                self.hashOutput = self.isUppercase ? hash.uppercased() : hash
                self.outputCharCount = self.hashOutput.count
                self.isProcessing = false
                self.performComparison()
            }
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            selectedFileURL = panel.url
            inputText = "" // Clear text input when file is selected
            characterCount = 0
            if let url = selectedFileURL {
                generateFileHash(url: url)
            }
        }
    }
    
    // MARK: - Comparison
    
    private func performComparison() {
        guard !compareHash.isEmpty && !hashOutput.isEmpty else {
            comparisonResult = .none
            return
        }
        
        let normalizedCompare = compareHash.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedOutput = hashOutput.lowercased()
        
        comparisonResult = normalizedCompare == normalizedOutput ? .match : .noMatch
    }
    
    // MARK: - Actions
    
    private func pasteInput() {
        if let string = NSPasteboard.general.string(forType: .string) {
            inputText = string
            selectedFileURL = nil // Clear file selection when pasting text
            updateCharacterCount()
        }
    }
    
    private func pasteCompareHash() {
        if let string = NSPasteboard.general.string(forType: .string) {
            compareHash = string
        }
    }
    
    private func clearAll() {
        inputText = ""
        selectedFileURL = nil
        hashOutput = ""
        compareHash = ""
        comparisonResult = .none
        secretKey = ""
        characterCount = 0
        outputCharCount = 0
    }
    
    private func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hashOutput, forType: .string)
    }
    
    private func updateCharacterCount() {
        characterCount = inputText.count
    }
}

// MARK: - Extensions

extension Digest {
    var hexString: String {
        self.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    var hexString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    HashGeneratorView()
}