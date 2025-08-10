//
//  JSONFormatterView.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI

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

#Preview {
    JSONFormatterView()
        .frame(width: 400, height: 500)
}