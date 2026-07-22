//
//  URLEncoderView.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI

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
    @FocusState private var isInputFocused: Bool

    enum URLMode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
        case analyze = "Analyze"
    }

    enum EncodeMode: String, CaseIterable {
        case standard = "Standard"
        case component = "Component"
        case formData = "Form Data"
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

    private var inputTitle: String {
        switch mode {
        case .encode: return "Text to Encode"
        case .decode: return "URL to Decode"
        case .analyze: return "URL to Analyze"
        }
    }

    private var inputPlaceholder: String {
        switch mode {
        case .encode: return "Paste or type text/URL to encode"
        case .decode: return "Paste encoded URL to decode"
        case .analyze: return "Paste URL to analyze"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode selection
            VStack(alignment: .leading, spacing: 10) {
                Picker("Mode", selection: $mode) {
                    ForEach(URLMode.allCases, id: \.self) { currentMode in
                        Text(currentMode.rawValue).tag(currentMode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .onChange(of: mode) {
                    if !inputText.isEmpty {
                        processURL()
                    }
                }

                // Encoding sub-mode (only for encode mode)
                if mode == .encode {
                    Picker("Encoding", selection: $encodeMode) {
                        ForEach(EncodeMode.allCases, id: \.self) { currentEncodeMode in
                            Text(currentEncodeMode.rawValue).tag(currentEncodeMode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .fixedSize()
                    .onChange(of: encodeMode) {
                        if !inputText.isEmpty {
                            processURL()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Input section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(inputTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

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
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Paste from clipboard")

                    Button(action: clearAll) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .disabled(inputText.isEmpty && outputText.isEmpty)
                    .help("Clear all")
                }
                .padding(.horizontal, 16)

                ZStack(alignment: .topLeading) {
                    UndoableTextEditor(text: $inputText) { newText in
                        updateCharacterCount()
                        if !newText.isEmpty {
                            processURL()
                        } else {
                            outputText = ""
                            outputCharCount = 0
                            parsedParams = []
                            urlComponents = nil
                            clearError()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if inputText.isEmpty {
                        Text(inputPlaceholder)
                            .font(.system(size: 12))
                            .foregroundColor(Color.secondary.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    errorMessage.isEmpty ? Color.secondary.opacity(0.15) : Color.red.opacity(0.5),
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

            // Output section
            if mode == .analyze && urlComponents != nil {
                // URL Analysis View
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // URL Components
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Text("URL Components")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)

                                if urlComponents?.isValid == true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.green)
                                        .symbolRenderingMode(.hierarchical)
                                }

                                Spacer()

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
                                .help("Copy components to clipboard")
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
                                    .fill(Color.primary.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }

                        // Query Parameters
                        if !parsedParams.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    Text("Query Parameters (\(parsedParams.count))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button(action: buildURLFromParams) {
                                        Label("Build", systemImage: "hammer")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .help("Build URL from parameters")

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

                                VStack(spacing: 0) {
                                    ForEach(Array(parsedParams.enumerated()), id: \.offset) { index, param in
                                        HStack(spacing: 6) {
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
                                        .background(index % 2 == 0 ? Color.primary.opacity(0.04) : Color.clear)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Regular output section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(mode == .encode ? "Encoded URL" : "Decoded Text")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

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

                            Button(action: swapInputOutput) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .disabled(outputText.isEmpty)
                            .help("Swap input and output")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    ZStack(alignment: .topLeading) {
                        UndoableTextEditor(text: $outputText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if outputText.isEmpty {
                            Text(mode == .encode ?
                                 "Encoded URL will appear here" :
                                 "Decoded text will appear here")
                                .font(.system(size: 12))
                                .foregroundColor(Color.secondary.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        !errorMessage.isEmpty && outputText.isEmpty ?
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
            }
        }
        .onAppear {
            isInputFocused = true
            #if DEBUG
            seedDemoContentIfRequested()
            #endif
        }
    }

    // MARK: - Actions

    #if DEBUG
    // Populates realistic content for marketing captures (`-DemoContent 1`).
    private func seedDemoContentIfRequested() {
        guard UserDefaults.standard.bool(forKey: "DemoContent") else { return }
        mode = .analyze
        inputText = "https://api.github.com/search/repositories?q=menu+bar+toolkit&language=swift&sort=stars&order=desc&page=1#results"
        updateCharacterCount()
        processURL()
    }
    #endif

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

#Preview {
    URLEncoderView()
        .frame(width: 400, height: 500)
}
