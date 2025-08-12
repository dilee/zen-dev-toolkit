//
//  JSONFormatterView.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI
import UniformTypeIdentifiers

struct JSONFormatterView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage = ""
    @State private var isValid = true
    @State private var characterCount = 0
    @State private var lineCount = 0
    @State private var selectedMode = "Format"
    @State private var jsonPathQuery = ""
    @State private var queryResults = ""
    @State private var queryError = ""
    @FocusState private var isInputFocused: Bool
    @FocusState private var isOutputFocused: Bool
    @FocusState private var isQueryFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode selector tabs
            HStack(spacing: 8) {
                ModeTabButton(title: "Format", icon: "text.alignleft", isSelected: selectedMode == "Format") {
                    selectedMode = "Format"
                    clearError()
                }
                
                ModeTabButton(title: "Query", icon: "magnifyingglass", isSelected: selectedMode == "Query") {
                    selectedMode = "Query"
                    clearError()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
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
                    .help("Load JSON from file")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                ZStack(alignment: .topLeading) {
                    UndoableTextEditor(text: $inputText) { newText in
                        updateCharacterCount()
                        if !newText.isEmpty {
                            validateJSON()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    if inputText.isEmpty {
                        Text("Paste or type JSON here...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.secondary.opacity(0.4))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if !errorMessage.isEmpty && selectedMode == "Format" {
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
            
            // Mode-specific action section
            if selectedMode == "Format" {
                // Format mode action buttons
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
            } else {
                // Query mode - JSONPath input and execute button
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.right.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            TextField("Enter JSONPath (e.g., $.store.book[0].title)", text: $jsonPathQuery)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                                .focused($isQueryFocused)
                                .onSubmit {
                                    executeJSONPath()
                                }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        Button(action: executeJSONPath) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 11))
                                Text("Query")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(jsonPathQuery.isEmpty ? Color.accentColor.opacity(0.3) : Color.accentColor)
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(jsonPathQuery.isEmpty || inputText.isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    
                    // Query error message
                    if !queryError.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 11))
                                .symbolRenderingMode(.multicolor)
                            Text(queryError)
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
                    }
                    
                    // Common JSONPath examples
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            JSONPathExample(path: "$", description: "Root") {
                                jsonPathQuery = "$"
                            }
                            JSONPathExample(path: "$.key", description: "Property") {
                                jsonPathQuery = "$.key"
                            }
                            JSONPathExample(path: "$..key", description: "Recursive") {
                                jsonPathQuery = "$..key"
                            }
                            JSONPathExample(path: "$[0]", description: "Index") {
                                jsonPathQuery = "$[0]"
                            }
                            JSONPathExample(path: "$[*]", description: "All items") {
                                jsonPathQuery = "$[*]"
                            }
                            JSONPathExample(path: "$[0:2]", description: "Slice") {
                                jsonPathQuery = "$[0:2]"
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Output section with modern design
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(selectedMode == "Format" ? "Output" : "Results")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if selectedMode == "Format" && isValid && !outputText.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    Spacer()
                    
                    if selectedMode == "Format" && !outputText.isEmpty {
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
                    } else if selectedMode == "Query" && !queryResults.isEmpty {
                        Button(action: copyQueryResultsToClipboard) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy results to clipboard")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                ZStack(alignment: .topLeading) {
                    if selectedMode == "Format" {
                        UndoableTextEditor(text: $outputText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        if outputText.isEmpty {
                            Text("Formatted JSON will appear here...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.4))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                        }
                    } else {
                        UndoableTextEditor(text: .constant(queryResults))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        if queryResults.isEmpty {
                            Text("Query results will appear here...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.4))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    selectedMode == "Format" && isValid && !outputText.isEmpty ? Color.green.opacity(0.4) : Color.secondary.opacity(0.2),
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
        .onChange(of: selectedMode) { _ in
            if selectedMode == "Query" && isQueryFocused == false {
                // Focus query field when switching to query mode
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isQueryFocused = true
                }
            }
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
            // First validate that it's valid JSON
            let data = inputText.data(using: .utf8) ?? Data()
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            
            // Format the JSON string while preserving key order
            if let formattedString = formatJSONString(inputText) {
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
            // First validate that it's valid JSON
            let data = inputText.data(using: .utf8) ?? Data()
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            
            // Minify the JSON string while preserving key order
            if let minifiedString = minifyJSONString(inputText) {
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
    
    private func loadFromFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a JSON file"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.json, .text, .plainText]
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    inputText = content
                    updateCharacterCount()
                    validateJSON()
                } catch {
                    errorMessage = "Unable to read file: \(error.localizedDescription)"
                    isValid = false
                }
            }
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
        queryError = ""
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
    
    // MARK: - JSON Formatting Helpers
    
    private func formatJSONString(_ jsonString: String) -> String? {
        // Use a more robust approach with proper JSON tokenization
        return formatJSONWithTokenizer(jsonString, minify: false)
    }
    
    private func minifyJSONString(_ jsonString: String) -> String? {
        // Use a more robust approach with proper JSON tokenization
        return formatJSONWithTokenizer(jsonString, minify: true)
    }
    
    private func formatJSONWithTokenizer(_ jsonString: String, minify: Bool) -> String? {
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        var result = ""
        var indentLevel = 0
        let indentString = "  " // 2 spaces for indentation
        var i = trimmed.startIndex
        
        while i < trimmed.endIndex {
            let char = trimmed[i]
            
            switch char {
            case "\"":
                // Handle string literals properly
                let (stringLiteral, nextIndex) = extractStringLiteral(from: trimmed, startingAt: i)
                result.append(stringLiteral)
                i = nextIndex
                continue
                
            case "{", "[":
                result.append(char)
                if !minify {
                    indentLevel += 1
                    result.append("\n")
                    result.append(String(repeating: indentString, count: indentLevel))
                }
                
            case "}", "]":
                if !minify {
                    indentLevel -= 1
                    result.append("\n")
                    result.append(String(repeating: indentString, count: indentLevel))
                }
                result.append(char)
                
            case ",":
                result.append(char)
                if !minify {
                    result.append("\n")
                    result.append(String(repeating: indentString, count: indentLevel))
                }
                
            case ":":
                result.append(char)
                if !minify {
                    result.append(" ")
                }
                
            case " ", "\t", "\n", "\r":
                // Skip whitespace when not in string (already handled by string extraction)
                break
                
            default:
                result.append(char)
            }
            
            i = trimmed.index(after: i)
        }
        
        return result.isEmpty ? nil : result
    }
    
    private func extractStringLiteral(from text: String, startingAt startIndex: String.Index) -> (String, String.Index) {
        var result = "\""  // Start with opening quote
        var i = text.index(after: startIndex)  // Skip opening quote
        var escaped = false
        
        while i < text.endIndex {
            let char = text[i]
            result.append(char)
            
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                // End of string literal
                i = text.index(after: i)
                break
            }
            
            i = text.index(after: i)
        }
        
        return (result, i)
    }
    
    // MARK: - JSONPath Query Functions
    
    private func executeJSONPath() {
        queryError = ""
        queryResults = ""
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            queryError = "Please enter JSON data first"
            return
        }
        
        guard !jsonPathQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            queryError = "Please enter a JSONPath query"
            return
        }
        
        do {
            let results = try JSONPathParser.query(json: inputText, path: jsonPathQuery)
            if results.isEmpty {
                queryResults = "No results found"
            } else {
                queryResults = JSONPathParser.formatResults(results)
            }
        } catch {
            queryError = error.localizedDescription
            queryResults = ""
        }
    }
    
    private func copyQueryResultsToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(queryResults, forType: .string)
    }
}

// MARK: - Supporting Views

struct ModeTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.clear : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct JSONPathExample: View {
    let path: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    JSONFormatterView()
        .frame(width: 400, height: 500)
}