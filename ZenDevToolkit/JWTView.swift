//
//  JWTView.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-12.
//

import SwiftUI
import Foundation
import CryptoKit
import CommonCrypto

struct JWTView: View {
    @State private var inputToken = ""
    @State private var secretKey = ""
    @State private var selectedMode: JWTMode = .decode
    @State private var selectedAlgorithm: JWTAlgorithm = .HS256
    @State private var headerJSON = ""
    @State private var payloadJSON = ""
    @State private var signatureStatus = ""
    @State private var errorMessage = ""
    @State private var isValid = true
    @State private var tokenParts: JWTParts?
    @State private var claims: JWTClaims?
    @State private var generatedToken = ""
    @State private var customClaims = ""
    @State private var showClaimsAsJSON = false
    @FocusState private var isInputFocused: Bool
    @FocusState private var isSecretFocused: Bool
    @FocusState private var isClaimsFocused: Bool
    
    enum JWTMode: String, CaseIterable {
        case decode = "Decode"
        case generate = "Generate"
        case verify = "Verify"
        
        var icon: String {
            switch self {
            case .decode: return "eye"
            case .generate: return "plus.circle"
            case .verify: return "checkmark.shield"
            }
        }
    }
    
    enum JWTAlgorithm: String, CaseIterable {
        case HS256 = "HS256"
        case HS384 = "HS384"
        case HS512 = "HS512"
        // RS256 removed - requires RSA key pair implementation
        
        var displayName: String { rawValue }
        var requiresSecret: Bool {
            // All current algorithms require a secret
            return true
        }
    }
    
    struct JWTParts {
        let header: String
        let payload: String
        let signature: String
        let headerDecoded: [String: Any]
        let payloadDecoded: [String: Any]
    }
    
    struct JWTClaims {
        let issuer: String?
        let subject: String?
        let audience: String?
        let expirationTime: Date?
        let notBefore: Date?
        let issuedAt: Date?
        let jwtID: String?
        let customClaims: [String: Any]
        
        var isExpired: Bool {
            guard let exp = expirationTime else { return false }
            return exp < Date()
        }
        
        var isNotYetValid: Bool {
            guard let nbf = notBefore else { return false }
            return nbf > Date()
        }
        
        var timeUntilExpiry: String? {
            guard let exp = expirationTime else { return nil }
            let interval = exp.timeIntervalSinceNow
            if interval <= 0 { return "Expired" }
            
            let hours = Int(interval) / 3600
            let minutes = Int(interval) % 3600 / 60
            if hours > 0 {
                return "\(hours)h \(minutes)m remaining"
            } else {
                return "\(minutes)m remaining"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode selector tabs
            HStack(spacing: 8) {
                ForEach(JWTMode.allCases, id: \.self) { mode in
                    JWTModeTabButton(title: mode.rawValue, icon: mode.icon, isSelected: selectedMode == mode) {
                        selectedMode = mode
                        clearError()
                        resetOutputs()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedMode {
                    case .decode:
                        decodeView
                    case .generate:
                        generateView
                    case .verify:
                        verifyView
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .onChange(of: selectedMode) { _, newMode in
            if newMode == .decode && !inputToken.isEmpty {
                decodeJWT()
            } else if newMode == .verify && !inputToken.isEmpty && !secretKey.isEmpty {
                verifyJWTSignature()
            }
        }
        .onChange(of: secretKey) { _, _ in
            if selectedMode == .verify && !inputToken.isEmpty {
                verifyJWTSignature()
            }
        }
    }
    
    // MARK: - Decode View
    private var decodeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Input Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("JWT Token")
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
                
                ZStack(alignment: .topLeading) {
                    UndoableTextEditor(text: $inputToken) { newText in
                        if selectedMode == .decode {
                            decodeJWT()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 100, maxHeight: 120)
                    
                    if inputToken.isEmpty {
                        Text("Paste your JWT token here...")
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
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
            }
            
            // Token Status
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
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            if tokenParts != nil {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Section
                    headerSection
                    
                    // Payload Section
                    payloadSection
                    
                    // Claims Section
                    if let claims = claims {
                        claimsSection(claims)
                    }
                    
                    // Signature Section
                    signatureSection
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Generate View
    private var generateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Algorithm Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Algorithm")
                    .font(.system(size: 12, weight: .semibold))
                
                Picker("", selection: $selectedAlgorithm) {
                    ForEach(JWTAlgorithm.allCases, id: \.self) { algorithm in
                        Text(algorithm.displayName).tag(algorithm)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 16)
            
            // Secret Key
            if selectedAlgorithm.requiresSecret {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secret Key")
                        .font(.system(size: 12, weight: .semibold))
                    
                    SecureField("Enter secret key", text: $secretKey)
                        .focused($isSecretFocused)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                }
                .padding(.horizontal, 16)
            }
            
            // Claims Input
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Claims (JSON)")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Spacer()
                    
                    Button(action: {
                        customClaims = """
                        {
                          "sub": "1234567890",
                          "name": "John Doe",
                          "admin": true,
                          "iat": \(Int(Date().timeIntervalSince1970)),
                          "exp": \(Int(Date().addingTimeInterval(3600).timeIntervalSince1970))
                        }
                        """
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 11))
                            Text("Sample")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Insert sample claims")
                }
                .padding(.horizontal, 16)
                
                ZStack(alignment: .topLeading) {
                    UndoableTextEditor(text: $customClaims) { _ in
                        // Claims updated
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 120, maxHeight: 120)
                    
                    if customClaims.isEmpty {
                        Text("Enter JSON claims...")
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
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
            }
            
            // Generate Button
            Button(action: generateJWT) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                    Text("Generate JWT")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((customClaims.isEmpty || (selectedAlgorithm.requiresSecret && secretKey.isEmpty)) ? Color.accentColor.opacity(0.3) : Color.accentColor)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(customClaims.isEmpty || (selectedAlgorithm.requiresSecret && secretKey.isEmpty))
            .padding(.horizontal, 16)
            
            // Generated Token Output
            if !generatedToken.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Generated JWT")
                            .font(.system(size: 12, weight: .semibold))
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard(generatedToken)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .help("Copy to clipboard")
                    }
                    
                    ZStack(alignment: .topLeading) {
                        UndoableTextEditor(text: .constant(generatedToken))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 120, maxHeight: 140)
                        
                        if generatedToken.isEmpty {
                            Text("Generated JWT will appear here...")
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
                                    .strokeBorder(Color.green.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 16)
            }
            
            // Error display
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
        }
    }
    
    // MARK: - Verify View
    private var verifyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Token Input
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("JWT Token")
                        .font(.system(size: 12, weight: .semibold))
                    
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
                
                ZStack(alignment: .topLeading) {
                    UndoableTextEditor(text: $inputToken) { newText in
                        if selectedMode == .verify && !secretKey.isEmpty {
                            verifyJWTSignature()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 100, maxHeight: 120)
                    
                    if inputToken.isEmpty {
                        Text("Paste your JWT token here...")
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
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
            }
            
            // Secret Key
            VStack(alignment: .leading, spacing: 8) {
                Text("Secret Key")
                    .font(.system(size: 12, weight: .semibold))
                
                SecureField("Enter secret key for verification", text: $secretKey)
                    .focused($isSecretFocused)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
            }
            .padding(.horizontal, 16)
            
            // Verify Button
            Button(action: verifyJWTSignature) {
                HStack {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 12))
                    Text("Verify Signature")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((inputToken.isEmpty || secretKey.isEmpty) ? Color.accentColor.opacity(0.3) : Color.accentColor)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(inputToken.isEmpty || secretKey.isEmpty)
            .padding(.horizontal, 16)
            
            // Verification Result
            if !signatureStatus.isEmpty {
                HStack {
                    Image(systemName: signatureStatus.contains("Valid") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(signatureStatus.contains("Valid") ? .green : .red)
                    Text(signatureStatus)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(signatureStatus.contains("Valid") ? .green : .red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((signatureStatus.contains("Valid") ? Color.green : Color.red).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
            }
            
            // Claims display for verification mode
            if let claims = claims {
                claimsSection(claims)
                    .padding(.horizontal, 16)
            }
            
            // Error display
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
        }
    }
    
    // MARK: - UI Components
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Header")
                    .font(.system(size: 12, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(headerJSON)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("Copy")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .help("Copy to clipboard")
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(headerJSON)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var payloadSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Payload")
                    .font(.system(size: 12, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(payloadJSON)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("Copy")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .help("Copy to clipboard")
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(payloadJSON)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func claimsSection(_ claims: JWTClaims) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Claims")
                    .font(.system(size: 12, weight: .semibold))
                
                Spacer()
                
                // Toggle between human-readable and JSON view
                HStack(spacing: 4) {
                    Button(action: {
                        showClaimsAsJSON = false
                    }) {
                        Text("Readable")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(!showClaimsAsJSON ? Color.accentColor : Color.secondary.opacity(0.1))
                            )
                            .foregroundColor(!showClaimsAsJSON ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showClaimsAsJSON = true
                    }) {
                        Text("JSON")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(showClaimsAsJSON ? Color.accentColor : Color.secondary.opacity(0.1))
                            )
                            .foregroundColor(showClaimsAsJSON ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
                
                if showClaimsAsJSON {
                    Button(action: {
                        copyToClipboard(payloadJSON)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                            Text("Copy")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Copy JSON to clipboard")
                }
            }
            
            if showClaimsAsJSON {
                // JSON view
                ScrollView {
                    Text(payloadJSON)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Human-readable view
                VStack(alignment: .leading, spacing: 8) {
                    // Standard claims
                    if let iss = claims.issuer {
                        ClaimRow(label: "Issuer (iss)", value: iss, type: .text)
                    }
                    if let sub = claims.subject {
                        ClaimRow(label: "Subject (sub)", value: sub, type: .text)
                    }
                    if let aud = claims.audience {
                        ClaimRow(label: "Audience (aud)", value: aud, type: .text)
                    }
                    if let exp = claims.expirationTime {
                        ClaimRow(label: "Expires (exp)", value: formatTimestamp(exp), type: claims.isExpired ? .expired : .valid, additionalInfo: claims.timeUntilExpiry)
                    }
                    if let nbf = claims.notBefore {
                        ClaimRow(label: "Not Before (nbf)", value: formatTimestamp(nbf), type: claims.isNotYetValid ? .warning : .valid)
                    }
                    if let iat = claims.issuedAt {
                        ClaimRow(label: "Issued At (iat)", value: formatTimestamp(iat), type: .text)
                    }
                    if let jti = claims.jwtID {
                        ClaimRow(label: "JWT ID (jti)", value: jti, type: .text)
                    }
                    
                    // Custom claims
                    if !claims.customClaims.isEmpty {
                        Text("Custom Claims")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        ForEach(Array(claims.customClaims.keys.sorted()), id: \.self) { key in
                            if !["iss", "sub", "aud", "exp", "nbf", "iat", "jti"].contains(key) {
                                ClaimRow(label: key, value: "\(claims.customClaims[key] ?? "")", type: .text)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signature")
                .font(.system(size: 12, weight: .semibold))
            
            HStack {
                Text("Signature verification requires the secret key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    selectedMode = .verify
                    resetOutputs()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 11))
                        Text("Go to Verify Tab")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .help("Switch to Verify mode")
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    // MARK: - Helper Functions
    private func decodeJWT() {
        resetOutputs()
        
        let parts = inputToken.components(separatedBy: ".")
        guard parts.count == 3 else {
            errorMessage = "Invalid JWT format. Expected 3 parts separated by dots."
            isValid = false
            return
        }
        
        do {
            // Decode header
            guard let headerData = base64URLDecode(parts[0]),
                  let headerDict = try JSONSerialization.jsonObject(with: headerData) as? [String: Any] else {
                errorMessage = "Failed to decode JWT header"
                isValid = false
                return
            }
            
            // Decode payload
            guard let payloadData = base64URLDecode(parts[1]),
                  let payloadDict = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
                errorMessage = "Failed to decode JWT payload"
                isValid = false
                return
            }
            
            // Format JSON
            let headerJSON = try JSONSerialization.data(withJSONObject: headerDict, options: [.prettyPrinted, .sortedKeys])
            let payloadJSON = try JSONSerialization.data(withJSONObject: payloadDict, options: [.prettyPrinted, .sortedKeys])
            
            self.headerJSON = String(data: headerJSON, encoding: .utf8) ?? ""
            self.payloadJSON = String(data: payloadJSON, encoding: .utf8) ?? ""
            
            // Create token parts
            tokenParts = JWTParts(
                header: parts[0],
                payload: parts[1],
                signature: parts[2],
                headerDecoded: headerDict,
                payloadDecoded: payloadDict
            )
            
            // Parse claims
            claims = parseJWTClaims(from: payloadDict)
            
            isValid = true
            errorMessage = ""
            
        } catch {
            errorMessage = "Error parsing JWT: \(error.localizedDescription)"
            isValid = false
        }
    }
    
    private func generateJWT() {
        resetOutputs()
        
        guard !customClaims.isEmpty else {
            errorMessage = "Claims are required"
            return
        }
        
        if selectedAlgorithm.requiresSecret && secretKey.isEmpty {
            errorMessage = "Secret key is required for HMAC algorithms"
            return
        }
        
        do {
            // Parse claims JSON
            guard let claimsData = customClaims.data(using: .utf8),
                  let claimsDict = try JSONSerialization.jsonObject(with: claimsData) as? [String: Any] else {
                errorMessage = "Invalid JSON in claims"
                return
            }
            
            // Create header
            let header = ["alg": selectedAlgorithm.rawValue, "typ": "JWT"]
            let headerData = try JSONSerialization.data(withJSONObject: header)
            let headerB64 = base64URLEncode(headerData)
            
            // Create payload
            let payloadData = try JSONSerialization.data(withJSONObject: claimsDict)
            let payloadB64 = base64URLEncode(payloadData)
            
            // Create signature
            let message = "\(headerB64).\(payloadB64)"
            let signature = try createSignature(message: message, algorithm: selectedAlgorithm, secret: secretKey)
            let signatureB64 = base64URLEncode(signature)
            
            generatedToken = "\(message).\(signatureB64)"
            errorMessage = ""
            
        } catch {
            errorMessage = "Error generating JWT: \(error.localizedDescription)"
        }
    }
    
    private func verifyJWTSignature() {
        guard !inputToken.isEmpty && !secretKey.isEmpty else {
            signatureStatus = "Token and secret key are required"
            return
        }
        
        let parts = inputToken.components(separatedBy: ".")
        guard parts.count == 3 else {
            signatureStatus = "Invalid JWT format"
            return
        }
        
        do {
            // Decode header to get algorithm
            guard let headerData = base64URLDecode(parts[0]),
                  let headerDict = try JSONSerialization.jsonObject(with: headerData) as? [String: Any],
                  let algString = headerDict["alg"] as? String,
                  let algorithm = JWTAlgorithm(rawValue: algString) else {
                signatureStatus = "Failed to parse JWT header or algorithm"
                return
            }
            
            // Create expected signature
            let message = "\(parts[0]).\(parts[1])"
            let expectedSignature = try createSignature(message: message, algorithm: algorithm, secret: secretKey)
            let expectedSignatureB64 = base64URLEncode(expectedSignature)
            
            // Compare signatures
            if parts[2] == expectedSignatureB64 {
                signatureStatus = "✓ Valid signature"
                
                // Also decode claims for display
                if let payloadData = base64URLDecode(parts[1]),
                   let payloadDict = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                    claims = parseJWTClaims(from: payloadDict)
                    
                    // Format payload JSON for display
                    let payloadJSONData = try JSONSerialization.data(withJSONObject: payloadDict, options: [.prettyPrinted, .sortedKeys])
                    self.payloadJSON = String(data: payloadJSONData, encoding: .utf8) ?? ""
                }
            } else {
                signatureStatus = "✗ Invalid signature"
                
                // Still decode and show claims even if signature is invalid
                if let payloadData = base64URLDecode(parts[1]),
                   let payloadDict = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                    claims = parseJWTClaims(from: payloadDict)
                    
                    // Format payload JSON for display
                    let payloadJSONData = try JSONSerialization.data(withJSONObject: payloadDict, options: [.prettyPrinted, .sortedKeys])
                    self.payloadJSON = String(data: payloadJSONData, encoding: .utf8) ?? ""
                }
            }
            
            errorMessage = ""
            
        } catch {
            signatureStatus = "Error verifying signature: \(error.localizedDescription)"
        }
    }
    
    private func parseJWTClaims(from payload: [String: Any]) -> JWTClaims {
        let issuer = payload["iss"] as? String
        let subject = payload["sub"] as? String
        let audience = payload["aud"] as? String
        let jwtID = payload["jti"] as? String
        
        let expirationTime: Date?
        if let exp = payload["exp"] as? TimeInterval {
            expirationTime = Date(timeIntervalSince1970: exp)
        } else if let expInt = payload["exp"] as? Int {
            expirationTime = Date(timeIntervalSince1970: Double(expInt))
        } else {
            expirationTime = nil
        }
        
        let notBefore: Date?
        if let nbf = payload["nbf"] as? TimeInterval {
            notBefore = Date(timeIntervalSince1970: nbf)
        } else if let nbfInt = payload["nbf"] as? Int {
            notBefore = Date(timeIntervalSince1970: Double(nbfInt))
        } else {
            notBefore = nil
        }
        
        let issuedAt: Date?
        if let iat = payload["iat"] as? TimeInterval {
            issuedAt = Date(timeIntervalSince1970: iat)
        } else if let iatInt = payload["iat"] as? Int {
            issuedAt = Date(timeIntervalSince1970: Double(iatInt))
        } else {
            issuedAt = nil
        }
        
        return JWTClaims(
            issuer: issuer,
            subject: subject,
            audience: audience,
            expirationTime: expirationTime,
            notBefore: notBefore,
            issuedAt: issuedAt,
            jwtID: jwtID,
            customClaims: payload
        )
    }
    
    private func createSignature(message: String, algorithm: JWTAlgorithm, secret: String) throws -> Data {
        let messageData = message.data(using: .utf8)!
        let secretData = secret.data(using: .utf8)!
        
        switch algorithm {
        case .HS256:
            return try hmacSHA256(data: messageData, key: secretData)
        case .HS384:
            return try hmacSHA384(data: messageData, key: secretData)
        case .HS512:
            return try hmacSHA512(data: messageData, key: secretData)
        }
    }
    
    private func hmacSHA256(data: Data, key: Data) throws -> Data {
        var result = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        result.withUnsafeMutableBytes { resultPtr in
            key.withUnsafeBytes { keyPtr in
                data.withUnsafeBytes { dataPtr in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyPtr.baseAddress, key.count, dataPtr.baseAddress, data.count, resultPtr.baseAddress)
                }
            }
        }
        return result
    }
    
    private func hmacSHA384(data: Data, key: Data) throws -> Data {
        var result = Data(count: Int(CC_SHA384_DIGEST_LENGTH))
        result.withUnsafeMutableBytes { resultPtr in
            key.withUnsafeBytes { keyPtr in
                data.withUnsafeBytes { dataPtr in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA384), keyPtr.baseAddress, key.count, dataPtr.baseAddress, data.count, resultPtr.baseAddress)
                }
            }
        }
        return result
    }
    
    private func hmacSHA512(data: Data, key: Data) throws -> Data {
        var result = Data(count: Int(CC_SHA512_DIGEST_LENGTH))
        result.withUnsafeMutableBytes { resultPtr in
            key.withUnsafeBytes { keyPtr in
                data.withUnsafeBytes { dataPtr in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512), keyPtr.baseAddress, key.count, dataPtr.baseAddress, data.count, resultPtr.baseAddress)
                }
            }
        }
        return result
    }
    
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64)
    }
    
    private func base64URLEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func clearInputs() {
        inputToken = ""
        secretKey = ""
        customClaims = ""
        resetOutputs()
    }
    
    private func resetOutputs() {
        headerJSON = ""
        payloadJSON = ""
        signatureStatus = ""
        errorMessage = ""
        tokenParts = nil
        claims = nil
        generatedToken = ""
        isValid = true
    }
    
    private func clearError() {
        errorMessage = ""
        isValid = true
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            inputToken = string.trimmingCharacters(in: .whitespacesAndNewlines)
            // Auto-decode if in decode mode
            if selectedMode == .decode && !inputToken.isEmpty {
                decodeJWT()
            }
            // Auto-verify if in verify mode and secret is present
            else if selectedMode == .verify && !inputToken.isEmpty && !secretKey.isEmpty {
                verifyJWTSignature()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Supporting Views and Types

struct JWTModeTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 16)
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

struct ClaimRow: View {
    let label: String
    let value: String
    let type: ClaimType
    let additionalInfo: String?
    
    init(label: String, value: String, type: ClaimType, additionalInfo: String? = nil) {
        self.label = label
        self.value = value
        self.type = type
        self.additionalInfo = additionalInfo
    }
    
    enum ClaimType {
        case text
        case valid
        case expired
        case warning
        
        var color: Color {
            switch self {
            case .text: return .primary
            case .valid: return .green
            case .expired: return .red
            case .warning: return .orange
            }
        }
        
        var icon: String? {
            switch self {
            case .text: return nil
            case .valid: return "checkmark.circle.fill"
            case .expired: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    if let icon = type.icon {
                        Image(systemName: icon)
                            .font(.system(size: 10))
                            .foregroundColor(type.color)
                    }
                    
                    Text(value)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(type.color)
                    
                    if let info = additionalInfo {
                        Text("(\(info))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

enum JWTError: LocalizedError {
    case unsupportedAlgorithm(String)
    case invalidToken(String)
    case signatureVerificationFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedAlgorithm(let alg):
            return "Unsupported algorithm: \(alg)"
        case .invalidToken(let reason):
            return "Invalid token: \(reason)"
        case .signatureVerificationFailed:
            return "Signature verification failed"
        }
    }
}

#Preview {
    JWTView()
        .frame(width: 420, height: 620)
}