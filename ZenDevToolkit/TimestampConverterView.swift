//
//  TimestampConverterView.swift
//  ZenDevToolkit
//
//  Created by Dilmi Dulanjali on 2025-08-11.
//

import SwiftUI
import Foundation

struct TimestampConverterView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage = ""
    @State private var isValid = true
    @State private var conversionMode: ConversionMode = .toHuman
    @State private var selectedTimezone = TimeZone.current
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @FocusState private var isInputFocused: Bool
    
    enum ConversionMode: CaseIterable {
        case toHuman
        case toTimestamp
        
        var title: String {
            switch self {
            case .toHuman: return "To Human"
            case .toTimestamp: return "To Timestamp"
            }
        }
        
        var inputPlaceholder: String {
            switch self {
            case .toHuman: return "Enter Unix timestamp (e.g., 1692123456)"
            case .toTimestamp: return "Enter date (e.g., 2024-08-11 14:30:00)"
            }
        }
        
        var outputPlaceholder: String {
            switch self {
            case .toHuman: return "Human-readable date will appear here..."
            case .toTimestamp: return "Unix timestamp will appear here..."
            }
        }
    }
    
    private var commonTimezones: [TimeZone] {
        let allTimezones = [
            TimeZone(identifier: "UTC")!,
            // Americas
            TimeZone(identifier: "America/New_York")!,      // Eastern Time
            TimeZone(identifier: "America/Chicago")!,       // Central Time
            TimeZone(identifier: "America/Denver")!,        // Mountain Time
            TimeZone(identifier: "America/Los_Angeles")!,   // Pacific Time
            TimeZone(identifier: "America/Toronto")!,       // Toronto
            TimeZone(identifier: "America/Vancouver")!,     // Vancouver
            TimeZone(identifier: "America/Sao_Paulo")!,     // Brazil
            TimeZone(identifier: "America/Mexico_City")!,   // Mexico
            TimeZone(identifier: "America/Buenos_Aires")!,  // Argentina
            TimeZone(identifier: "America/Bogota")!,        // Colombia
            TimeZone(identifier: "America/Lima")!,          // Peru
            // Europe
            TimeZone(identifier: "Europe/London")!,         // GMT/BST
            TimeZone(identifier: "Europe/Paris")!,          // CET
            TimeZone(identifier: "Europe/Berlin")!,         // CET
            TimeZone(identifier: "Europe/Rome")!,           // CET
            TimeZone(identifier: "Europe/Madrid")!,         // CET
            TimeZone(identifier: "Europe/Amsterdam")!,      // CET
            TimeZone(identifier: "Europe/Stockholm")!,      // CET
            TimeZone(identifier: "Europe/Moscow")!,         // MSK
            TimeZone(identifier: "Europe/Athens")!,         // EET
            TimeZone(identifier: "Europe/Istanbul")!,       // TRT
            TimeZone(identifier: "Europe/Zurich")!,         // CET
            TimeZone(identifier: "Europe/Brussels")!,       // CET
            TimeZone(identifier: "Europe/Warsaw")!,         // CET
            TimeZone(identifier: "Europe/Vienna")!,         // CET
            TimeZone(identifier: "Europe/Lisbon")!,         // WET
            // Asia
            TimeZone(identifier: "Asia/Tokyo")!,            // JST
            TimeZone(identifier: "Asia/Shanghai")!,         // CST
            TimeZone(identifier: "Asia/Hong_Kong")!,        // HKT
            TimeZone(identifier: "Asia/Singapore")!,        // SGT
            TimeZone(identifier: "Asia/Seoul")!,            // KST
            TimeZone(identifier: "Asia/Kolkata")!,          // IST
            TimeZone(identifier: "Asia/Dubai")!,            // GST
            TimeZone(identifier: "Asia/Bangkok")!,          // ICT
            TimeZone(identifier: "Asia/Jakarta")!,          // WIB
            TimeZone(identifier: "Asia/Manila")!,           // PHT
            TimeZone(identifier: "Asia/Taipei")!,           // CST
            TimeZone(identifier: "Asia/Karachi")!,          // PKT
            TimeZone(identifier: "Asia/Tehran")!,           // IRST
            TimeZone(identifier: "Asia/Tel_Aviv")!,         // IST
            TimeZone(identifier: "Asia/Riyadh")!,           // AST
            TimeZone(identifier: "Asia/Kuala_Lumpur")!,     // MYT
            TimeZone(identifier: "Asia/Ho_Chi_Minh")!,      // ICT
            TimeZone(identifier: "Asia/Colombo")!,          // IST
            TimeZone(identifier: "Asia/Dhaka")!,            // BST
            TimeZone(identifier: "Asia/Kathmandu")!,        // NPT
            // Africa
            TimeZone(identifier: "Africa/Cairo")!,          // EET
            TimeZone(identifier: "Africa/Johannesburg")!,   // SAST
            TimeZone(identifier: "Africa/Lagos")!,          // WAT
            TimeZone(identifier: "Africa/Nairobi")!,        // EAT
            TimeZone(identifier: "Africa/Casablanca")!,     // WET
            // Pacific
            TimeZone(identifier: "Australia/Sydney")!,      // AEDT
            TimeZone(identifier: "Australia/Melbourne")!,   // AEDT
            TimeZone(identifier: "Australia/Brisbane")!,    // AEST
            TimeZone(identifier: "Australia/Perth")!,       // AWST
            TimeZone(identifier: "Australia/Adelaide")!,    // ACDT
            TimeZone(identifier: "Pacific/Auckland")!,      // NZDT
            TimeZone(identifier: "Pacific/Fiji")!,          // FJT
            TimeZone(identifier: "Pacific/Honolulu")!,      // HST
        ].compactMap { $0 }
        
        // Sort all timezones by UTC offset
        let sortedTimezones = allTimezones.sorted { tz1, tz2 in
            let offset1 = tz1.secondsFromGMT()
            let offset2 = tz2.secondsFromGMT()
            
            // If offsets are equal, sort alphabetically by identifier
            if offset1 == offset2 {
                return tz1.identifier < tz2.identifier
            }
            return offset1 < offset2
        }
        
        // Add current timezone at the top, but avoid duplicates in the sorted list
        var result = [TimeZone.current]
        
        // Add separator indicator (this is just for organization, not an actual timezone)
        for timezone in sortedTimezones {
            if timezone.identifier != TimeZone.current.identifier {
                result.append(timezone)
            }
        }
        
        return result
    }
    
    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(ConversionMode.allCases, id: \.self) { currentMode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            conversionMode = currentMode
                            // Auto-convert if there's input
                            if !inputText.isEmpty {
                                convertTimestamp()
                            }
                        }
                    }) {
                        Text(currentMode.title)
                            .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(conversionMode == currentMode ? Color.accentColor : Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(conversionMode == currentMode ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Current time button
                Button(action: insertCurrentTimestamp) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("Now")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .help(conversionMode == .toHuman ? "Insert current timestamp" : "Insert current date/time")
                
                // Date picker button (only show in "To Timestamp" mode)
                if conversionMode == .toTimestamp {
                    Button(action: { showDatePicker.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text("Pick")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Pick date and time")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Timezone selector for both conversion modes
            Picker("Time zone", selection: $selectedTimezone) {
                ForEach(commonTimezones, id: \.self) { timezone in
                    Text(timezoneDisplayName(for: timezone)).tag(timezone)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            // Date picker (only show in "To Timestamp" mode and when toggled)
            if conversionMode == .toTimestamp && showDatePicker {
                HStack {
                    Text("Date and Time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.timeZone, selectedTimezone)
                        .onChange(of: selectedDate) {
                            insertSelectedDate()
                        }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            modeSelector
            
            // Input section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Input")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
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
                .padding(.top, 12)
                
                ZStack(alignment: .topLeading) {
                    UndoableTextEditor(text: $inputText) { newText in
                        if !newText.isEmpty {
                            convertTimestamp()
                        } else {
                            clearOutput()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focused($isInputFocused)
                    
                    if inputText.isEmpty {
                        Text(conversionMode.inputPlaceholder)
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
                .frame(minHeight: 80, idealHeight: 100, maxHeight: 120)
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
                        .lineLimit(2)
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
                Button(action: convertTimestamp) {
                    HStack {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.system(size: 12))
                        Text("Convert")
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
                    UndoableTextEditor(text: $outputText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    if outputText.isEmpty {
                        Text(conversionMode.outputPlaceholder)
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
            isInputFocused = true
        }
        .onChange(of: conversionMode) {
            clearAll()
            showDatePicker = false
        }
        .onChange(of: selectedTimezone) {
            if !inputText.isEmpty {
                convertTimestamp()
            }
            // Update the date picker's timezone
            if showDatePicker {
                selectedDate = selectedDate
            }
        }
    }
    
    // MARK: - Actions
    
    private func convertTimestamp() {
        clearError()
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter a timestamp or date to convert")
            return
        }
        
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch conversionMode {
        case .toHuman:
            convertTimestampToHuman(trimmedInput)
        case .toTimestamp:
            convertHumanToTimestamp(trimmedInput)
        }
    }
    
    private func convertTimestampToHuman(_ input: String) {
        // Try to parse as Unix timestamp (seconds or milliseconds)
        if let timestamp = Double(input) {
            let date: Date
            
            // Detect if it's milliseconds (likely if > 1e10)
            if timestamp > 1e10 {
                date = Date(timeIntervalSince1970: timestamp / 1000.0)
            } else {
                date = Date(timeIntervalSince1970: timestamp)
            }
            
            let formatter = DateFormatter()
            formatter.timeZone = selectedTimezone
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
            
            let humanReadable = formatter.string(from: date)
            
            // Additional formats
            formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a z"
            let longFormat = formatter.string(from: date)
            
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let isoFormat = formatter.string(from: date)
            
            outputText = """
            \(humanReadable)
            
            Long format: \(longFormat)
            ISO format: \(isoFormat)
            Relative: \(timeAgo(from: date))
            """
            
            isValid = true
        } else {
            showError("Invalid timestamp format. Please enter a Unix timestamp (seconds or milliseconds).")
        }
    }
    
    private func convertHumanToTimestamp(_ input: String) {
        // First, normalize the input to handle AM/PM format
        let normalizedInput = normalizeTimeFormat(input)
        
        let formatters = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "MM/dd/yyyy",
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm",
            "dd/MM/yyyy",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            // AM/PM formats
            "yyyy-MM-dd h:mm:ss a",
            "yyyy-MM-dd h:mm a",
            "MM/dd/yyyy h:mm:ss a",
            "MM/dd/yyyy h:mm a",
            "dd/MM/yyyy h:mm:ss a",
            "dd/MM/yyyy h:mm a"
        ]
        
        for formatString in formatters {
            let formatter = DateFormatter()
            formatter.timeZone = selectedTimezone
            formatter.dateFormat = formatString
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatter.date(from: normalizedInput) {
                let timestamp = date.timeIntervalSince1970
                let milliseconds = Int64(timestamp * 1000)
                
                outputText = """
                Unix timestamp (seconds): \(Int64(timestamp))
                Unix timestamp (milliseconds): \(milliseconds)
                
                Formatted: \(DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .full))
                """
                
                isValid = true
                return
            }
        }
        
        showError("Invalid date format. Try formats like: 2024-08-11 14:30:00, 08/11/2024, or ISO 8601")
    }
    
    private func insertCurrentTimestamp() {
        let now = Date()
        
        switch conversionMode {
        case .toHuman:
            // Insert Unix timestamp
            let currentTimestamp = Int64(now.timeIntervalSince1970)
            inputText = String(currentTimestamp)
        case .toTimestamp:
            // Insert human-readable date/time
            let formatter = DateFormatter()
            formatter.timeZone = selectedTimezone
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            inputText = formatter.string(from: now)
        }
        
        convertTimestamp()
    }
    
    private func insertSelectedDate() {
        let formatter = DateFormatter()
        formatter.timeZone = selectedTimezone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Force 24-hour format
        
        inputText = formatter.string(from: selectedDate)
        convertTimestamp()
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            inputText = string
            if !inputText.isEmpty {
                convertTimestamp()
            }
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputText, forType: .string)
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
        showDatePicker = false
        clearError()
    }
    
    private func clearOutput() {
        outputText = ""
        clearError()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        outputText = ""
        isValid = false
    }
    
    private func clearError() {
        errorMessage = ""
        isValid = true
    }
    
    private func timezoneDisplayName(for timezone: TimeZone) -> String {
        // Get UTC offset
        let offset = timezone.secondsFromGMT()
        let hours = abs(offset) / 3600
        let minutes = (abs(offset) % 3600) / 60
        let sign = offset >= 0 ? "+" : "-"
        let offsetString = minutes > 0 ? String(format: "%@%02d:%02d", sign, hours, minutes) : String(format: "%@%02d:00", sign, hours)
        
        if timezone == TimeZone.current {
            let cityName = getSimpleCityName(for: timezone)
            return "✓ Current • \(cityName) (UTC\(offsetString))"
        }
        
        let displayNames: [String: String] = [
            "UTC": "UTC • Universal Time",
            // Americas
            "America/New_York": "New York • Eastern Time",
            "America/Chicago": "Chicago • Central Time",
            "America/Denver": "Denver • Mountain Time",
            "America/Los_Angeles": "Los Angeles • Pacific Time",
            "America/Toronto": "Toronto",
            "America/Vancouver": "Vancouver",
            "America/Sao_Paulo": "São Paulo • Brazil",
            "America/Mexico_City": "Mexico City",
            "America/Buenos_Aires": "Buenos Aires • Argentina",
            "America/Bogota": "Bogotá • Colombia",
            "America/Lima": "Lima • Peru",
            // Europe
            "Europe/London": "London • GMT/BST",
            "Europe/Paris": "Paris • France",
            "Europe/Berlin": "Berlin • Germany",
            "Europe/Rome": "Rome • Italy",
            "Europe/Madrid": "Madrid • Spain",
            "Europe/Amsterdam": "Amsterdam • Netherlands",
            "Europe/Stockholm": "Stockholm • Sweden",
            "Europe/Moscow": "Moscow • Russia",
            "Europe/Athens": "Athens • Greece",
            "Europe/Istanbul": "Istanbul • Turkey",
            "Europe/Zurich": "Zurich • Switzerland",
            "Europe/Brussels": "Brussels • Belgium",
            "Europe/Warsaw": "Warsaw • Poland",
            "Europe/Vienna": "Vienna • Austria",
            "Europe/Lisbon": "Lisbon • Portugal",
            // Asia
            "Asia/Tokyo": "Tokyo • Japan",
            "Asia/Shanghai": "Shanghai • China",
            "Asia/Hong_Kong": "Hong Kong",
            "Asia/Singapore": "Singapore",
            "Asia/Seoul": "Seoul • South Korea",
            "Asia/Kolkata": "Kolkata • India",
            "Asia/Dubai": "Dubai • UAE",
            "Asia/Bangkok": "Bangkok • Thailand",
            "Asia/Jakarta": "Jakarta • Indonesia",
            "Asia/Manila": "Manila • Philippines",
            "Asia/Taipei": "Taipei • Taiwan",
            "Asia/Karachi": "Karachi • Pakistan",
            "Asia/Tehran": "Tehran • Iran",
            "Asia/Tel_Aviv": "Tel Aviv • Israel",
            "Asia/Riyadh": "Riyadh • Saudi Arabia",
            "Asia/Kuala_Lumpur": "Kuala Lumpur • Malaysia",
            "Asia/Ho_Chi_Minh": "Ho Chi Minh • Vietnam",
            "Asia/Colombo": "Colombo • Sri Lanka",
            "Asia/Dhaka": "Dhaka • Bangladesh",
            "Asia/Kathmandu": "Kathmandu • Nepal",
            // Africa
            "Africa/Cairo": "Cairo • Egypt",
            "Africa/Johannesburg": "Johannesburg • South Africa",
            "Africa/Lagos": "Lagos • Nigeria",
            "Africa/Nairobi": "Nairobi • Kenya",
            "Africa/Casablanca": "Casablanca • Morocco",
            // Pacific
            "Australia/Sydney": "Sydney • Australia",
            "Australia/Melbourne": "Melbourne • Australia",
            "Australia/Brisbane": "Brisbane • Australia",
            "Australia/Perth": "Perth • Australia",
            "Australia/Adelaide": "Adelaide • Australia",
            "Pacific/Auckland": "Auckland • New Zealand",
            "Pacific/Fiji": "Fiji",
            "Pacific/Honolulu": "Honolulu • Hawaii"
        ]
        
        let cityName = displayNames[timezone.identifier] ?? timezone.identifier
        
        // Special handling for UTC
        if timezone.identifier == "UTC" {
            return "UTC+00:00 • Universal Time"
        }
        
        return "UTC\(offsetString) • \(cityName)"
    }
    
    private func getSimpleCityName(for timezone: TimeZone) -> String {
        // Extract city name from identifier
        if let lastComponent = timezone.identifier.split(separator: "/").last {
            return String(lastComponent).replacingOccurrences(of: "_", with: " ")
        }
        return timezone.identifier
    }
    
    private func normalizeTimeFormat(_ input: String) -> String {
        // Handle AM/PM format conversion
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it contains AM/PM
        if normalized.contains(" AM") || normalized.contains(" PM") {
            // Let the DateFormatter handle AM/PM parsing directly
            return normalized
        }
        
        return normalized
    }
    
    private func timeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        let absInterval = abs(interval)
        
        // Determine if it's past or future
        let isPast = interval > 0
        let suffix = isPast ? " ago" : " from now"
        
        if absInterval < 60 {
            return "just now"
        } else if absInterval < 3600 {
            let minutes = Int(absInterval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")\(suffix)"
        } else if absInterval < 86400 {
            let hours = Int(absInterval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s")\(suffix)"
        } else if absInterval < 2592000 {
            let days = Int(absInterval / 86400)
            return "\(days) day\(days == 1 ? "" : "s")\(suffix)"
        } else if absInterval < 31536000 {
            let months = Int(absInterval / 2592000)
            return "\(months) month\(months == 1 ? "" : "s")\(suffix)"
        } else {
            let years = Int(absInterval / 31536000)
            return "\(years) year\(years == 1 ? "" : "s")\(suffix)"
        }
    }
}

#Preview {
    TimestampConverterView()
        .frame(width: 420, height: 620)
}
