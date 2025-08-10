import SwiftUI

struct UUIDGeneratorView: View {
    @State private var generatedUUIDs: [String] = []
    @State private var selectedFormat = UUIDFormat.standard
    @State private var numberOfUUIDs = 1
    @State private var isUppercase = false
    @State private var selectedUUID: String?
    @State private var bulkGenerationCount = "10"
    @State private var showingBulkSheet = false
    @FocusState private var isBulkInputFocused: Bool
    
    enum UUIDFormat: String, CaseIterable {
        case standard = "Standard"
        case withoutHyphens = "No Hyphens"
        case withBraces = "With Braces"
        case urn = "URN"
        
        var displayName: String { rawValue }
        
        func format(_ uuid: UUID) -> String {
            let uuidString = uuid.uuidString
            switch self {
            case .standard:
                return uuidString
            case .withoutHyphens:
                return uuidString.replacingOccurrences(of: "-", with: "")
            case .withBraces:
                return "{\(uuidString)}"
            case .urn:
                return "urn:uuid:\(uuidString)"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Options section
            VStack(spacing: 12) {
                // Format Selection
                HStack(spacing: 8) {
                    ForEach(UUIDFormat.allCases, id: \.self) { format in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedFormat = format
                                reformatUUIDs()
                            }
                        }) {
                            Text(format.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedFormat == format ? Color.accentColor : Color.secondary.opacity(0.1))
                                )
                                .foregroundColor(selectedFormat == format ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Options
                HStack(spacing: 16) {
                    Toggle(isOn: $isUppercase) {
                        HStack(spacing: 4) {
                            Image(systemName: "textformat")
                                .font(.system(size: 11))
                            Text("Uppercase")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .toggleStyle(.checkbox)
                    .onChange(of: isUppercase) {
                        reformatUUIDs()
                    }
                    
                    Spacer()
                    
                    Button(action: { showingBulkSheet.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 11))
                            Text("Bulk Generate")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Generate multiple UUIDs")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Action buttons
            HStack(spacing: 10) {
                Button(action: generateNewUUID) {
                    HStack {
                        Image(systemName: "plus.square")
                            .font(.system(size: 12))
                        Text("Generate UUID")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
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
                .disabled(generatedUUIDs.isEmpty)
                .help("Clear all")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Generated UUIDs section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Generated UUIDs")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if !generatedUUIDs.isEmpty {
                        Text("\(generatedUUIDs.count) UUID\(generatedUUIDs.count == 1 ? "" : "s")")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    if !generatedUUIDs.isEmpty {
                        Button(action: copyAllUUIDs) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy All")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy all UUIDs to clipboard")
                    }
                }
                .padding(.horizontal, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if generatedUUIDs.isEmpty {
                            Text("Generated UUIDs will appear here...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.4))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(Array(generatedUUIDs.enumerated()), id: \.offset) { index, uuid in
                                HStack(spacing: 8) {
                                    Text(uuid)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(selectedUUID == uuid ? .white : .primary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(selectedUUID == uuid ? Color.accentColor : Color.secondary.opacity(0.05))
                                        )
                                        .onTapGesture {
                                            selectedUUID = uuid
                                        }
                                    
                                    Button(action: { copyUUID(uuid) }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Copy UUID")
                                    
                                    Button(action: { removeUUID(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Remove UUID")
                                }
                                .padding(.horizontal, 12)
                            }
                        }
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
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            Spacer()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingBulkSheet) {
            BulkGenerateSheet(
                count: $bulkGenerationCount,
                onGenerate: { count in
                    generateBulkUUIDs(count: count)
                    showingBulkSheet = false
                }
            )
        }
        .onAppear {
            generateNewUUID()
        }
    }
    
    // MARK: - UUID Generation
    
    private func generateNewUUID() {
        let uuid = UUID()
        let formattedUUID = formatUUID(uuid)
        generatedUUIDs.insert(formattedUUID, at: 0)
        selectedUUID = formattedUUID
    }
    
    private func generateBulkUUIDs(count: Int) {
        for _ in 0..<count {
            let uuid = UUID()
            let formattedUUID = formatUUID(uuid)
            generatedUUIDs.insert(formattedUUID, at: 0)
        }
        if !generatedUUIDs.isEmpty {
            selectedUUID = generatedUUIDs.first
        }
    }
    
    private func formatUUID(_ uuid: UUID) -> String {
        let formatted = selectedFormat.format(uuid)
        return isUppercase ? formatted.uppercased() : formatted.lowercased()
    }
    
    private func reformatUUIDs() {
        generatedUUIDs = generatedUUIDs.map { uuidString in
            // Extract the base UUID from any format
            let cleanedUUID = extractBaseUUID(from: uuidString)
            
            // Parse and reformat
            if let uuid = UUID(uuidString: cleanedUUID) {
                return formatUUID(uuid)
            }
            return uuidString
        }
    }
    
    private func extractBaseUUID(from string: String) -> String {
        var cleaned = string.lowercased()
        
        // Remove URN prefix
        cleaned = cleaned.replacingOccurrences(of: "urn:uuid:", with: "")
        
        // Remove braces
        cleaned = cleaned.replacingOccurrences(of: "{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "}", with: "")
        
        // Add hyphens if missing
        if !cleaned.contains("-") && cleaned.count == 32 {
            let index8 = cleaned.index(cleaned.startIndex, offsetBy: 8)
            let index12 = cleaned.index(cleaned.startIndex, offsetBy: 12)
            let index16 = cleaned.index(cleaned.startIndex, offsetBy: 16)
            let index20 = cleaned.index(cleaned.startIndex, offsetBy: 20)
            
            cleaned = String(cleaned[..<index8]) + "-" +
                     String(cleaned[index8..<index12]) + "-" +
                     String(cleaned[index12..<index16]) + "-" +
                     String(cleaned[index16..<index20]) + "-" +
                     String(cleaned[index20...])
        }
        
        return cleaned
    }
    
    // MARK: - Actions
    
    private func copyUUID(_ uuid: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(uuid, forType: .string)
    }
    
    private func copyAllUUIDs() {
        let allUUIDs = generatedUUIDs.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(allUUIDs, forType: .string)
    }
    
    private func removeUUID(at index: Int) {
        guard index < generatedUUIDs.count else { return }
        let removedUUID = generatedUUIDs[index]
        generatedUUIDs.remove(at: index)
        
        if selectedUUID == removedUUID {
            selectedUUID = generatedUUIDs.first
        }
    }
    
    private func clearAll() {
        generatedUUIDs.removeAll()
        selectedUUID = nil
    }
}

// MARK: - Bulk Generate Sheet

struct BulkGenerateSheet: View {
    @Binding var count: String
    let onGenerate: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Bulk Generate UUIDs")
                .font(.system(size: 14, weight: .semibold))
            
            HStack {
                Text("Number of UUIDs:")
                    .font(.system(size: 12))
                
                TextField("10", text: $count)
                    .font(.system(size: 12, design: .monospaced))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .focused($isInputFocused)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Button("Generate") {
                    if let intCount = Int(count), intCount > 0 && intCount <= 1000 {
                        onGenerate(intCount)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidCount)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 250)
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var isValidCount: Bool {
        if let intCount = Int(count) {
            return intCount > 0 && intCount <= 1000
        }
        return false
    }
}

#Preview {
    UUIDGeneratorView()
}