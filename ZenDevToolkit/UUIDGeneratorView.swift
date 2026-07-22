import SwiftUI

struct UUIDGeneratorView: View {
    @State private var generatedUUIDs: [String] = []
    @AppStorage("uuidVersion") private var selectedVersion = UUIDVersion.v4
    @State private var selectedFormat = UUIDFormat.standard
    @State private var isUppercase = false
    @State private var selectedUUID: String?
    @State private var hoveredIndex: Int?
    @State private var bulkGenerationCount = "10"
    @State private var showingBulkSheet = false
    @FocusState private var isBulkInputFocused: Bool

    enum UUIDVersion: String, CaseIterable {
        case v4 = "v4"
        case v7 = "v7"

        var displayName: String { rawValue }

        var helpText: String {
            switch self {
            case .v4:
                return "Random (v4)"
            case .v7:
                return "Time-ordered (RFC 9562)"
            }
        }
    }

    enum UUIDFormat: String, CaseIterable {
        case standard = "Standard"
        case withoutHyphens = "No Hyphens"
        case withBraces = "With Braces"
        case urn = "URN"

        var displayName: String { rawValue }

        // Shorter segment label so all four options fit the segmented picker.
        var segmentLabel: String {
            switch self {
            case .standard: return "Standard"
            case .withoutHyphens: return "No Hyphens"
            case .withBraces: return "Braces"
            case .urn: return "URN"
            }
        }

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
            // Version + options
            HStack(spacing: 10) {
                Picker("Version", selection: $selectedVersion) {
                    ForEach(UUIDVersion.allCases, id: \.self) { version in
                        Text(version.displayName)
                            .help(version.helpText)
                            .tag(version)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()

                Spacer()

                Toggle("Uppercase", isOn: $isUppercase)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .onChange(of: isUppercase) {
                        reformatUUIDs()
                    }
                    .help("Format generated UUIDs in uppercase")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Format selection
            Picker("Format", selection: $selectedFormat) {
                ForEach(UUIDFormat.allCases, id: \.self) { format in
                    Text(format.segmentLabel).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
            .onChange(of: selectedFormat) {
                reformatUUIDs()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Actions
            HStack(spacing: 10) {
                Button("Generate", action: generateNewUUID)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)

                Button("Bulk Generate…") {
                    showingBulkSheet = true
                }
                .buttonStyle(.bordered)
                .help("Generate multiple UUIDs")

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Generated UUIDs section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text("Generated UUIDs")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

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
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy all UUIDs to clipboard")

                        Button(action: clearAll) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help("Clear all")
                    }
                }
                .padding(.horizontal, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        if generatedUUIDs.isEmpty {
                            Text("Generated UUIDs will appear here...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.5))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(Array(generatedUUIDs.enumerated()), id: \.offset) { index, uuid in
                                HStack(spacing: 8) {
                                    Text(uuid)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedUUID = uuid
                                        }

                                    Button(action: { copyUUID(uuid) }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                    .help("Copy UUID")

                                    Button(action: { removeUUID(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                    .help("Remove UUID")
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(rowBackground(uuid: uuid, index: index))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(
                                            selectedUUID == uuid ? Color.accentColor.opacity(0.4) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                                .onHover { hovering in
                                    if hovering {
                                        hoveredIndex = index
                                    } else if hoveredIndex == index {
                                        hoveredIndex = nil
                                    }
                                }
                                .padding(.horizontal, 10)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 4)
        }
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
            #if DEBUG
            seedDemoContentIfRequested()
            #endif
        }
    }

    // MARK: - Row Styling

    private func rowBackground(uuid: String, index: Int) -> Color {
        if selectedUUID == uuid {
            return Color.accentColor.opacity(0.12)
        }
        if hoveredIndex == index {
            return Color.secondary.opacity(0.10)
        }
        return Color.secondary.opacity(0.05)
    }

    // MARK: - UUID Generation

    #if DEBUG
    // Populates realistic content for marketing captures (`-DemoContent 1`).
    private func seedDemoContentIfRequested() {
        guard UserDefaults.standard.bool(forKey: "DemoContent") else { return }
        selectedVersion = .v7
        generatedUUIDs.removeAll()
        selectedUUID = nil
        for _ in 0..<6 {
            generateNewUUID()
        }
    }
    #endif

    private func generateNewUUID() {
        let uuid = makeUUID()
        let formattedUUID = formatUUID(uuid)
        generatedUUIDs.insert(formattedUUID, at: 0)
        selectedUUID = formattedUUID
    }

    private func generateBulkUUIDs(count: Int) {
        for _ in 0..<count {
            let uuid = makeUUID()
            let formattedUUID = formatUUID(uuid)
            generatedUUIDs.insert(formattedUUID, at: 0)
        }
        if !generatedUUIDs.isEmpty {
            selectedUUID = generatedUUIDs.first
        }
    }

    private func makeUUID() -> UUID {
        switch selectedVersion {
        case .v4:
            return UUID()
        case .v7:
            return UUIDv7.generate()
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
        hoveredIndex = nil
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
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .focused($isInputFocused)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

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
