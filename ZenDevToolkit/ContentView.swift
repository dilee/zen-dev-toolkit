//
//  ContentView.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTool = "JSON"
    @ObservedObject var updateChecker = UpdateChecker.shared
    @State private var showUpdateBanner = false
    
    // Dynamic height based on banner visibility
    var windowHeight: CGFloat {
        showUpdateBanner && updateChecker.updateAvailable ? 730 : 680 // Add 50px for banner when visible
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // FIXED header that NEVER moves
            HStack(spacing: 6) {
                CompactToolButton(icon: "curlybraces", title: "JSON", tag: "JSON", selection: $selectedTool)
                CompactToolButton(icon: "abc", title: "Base64", tag: "Base64", selection: $selectedTool)
                CompactToolButton(icon: "link", title: "URL", tag: "URL", selection: $selectedTool)
                CompactToolButton(icon: "number.square", title: "Hash", tag: "Hash", selection: $selectedTool)
                CompactToolButton(icon: "key", title: "UUID", tag: "UUID", selection: $selectedTool)
                CompactToolButton(icon: "calendar.badge.clock", title: "Time", tag: "Time", selection: $selectedTool)
                CompactToolButton(icon: "person.badge.key", title: "JWT", tag: "JWT", selection: $selectedTool)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            
            // Tool content - use fixed size container
            VStack {
                switch selectedTool {
                case "JSON":
                    JSONFormatterView()
                case "Base64":
                    Base64View()
                case "URL":
                    URLEncoderView()
                case "Hash":
                    HashGeneratorView()
                case "UUID":
                    UUIDGeneratorView()
                case "Time":
                    TimestampConverterView()
                case "JWT":
                    JWTView()
                default:
                    Text("Select a tool")
                }
            }
            .frame(width: 420, height: 620) // Fixed size for all views
            .background(Color(NSColor.windowBackgroundColor))
            .animation(.none, value: selectedTool) // Disable animation
            
            // Update notification banner at the bottom
            if showUpdateBanner && updateChecker.updateAvailable {
                UpdateBannerView(showBanner: $showUpdateBanner, latestVersion: updateChecker.latestVersion)
                    .frame(height: 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 420, height: windowHeight)
        .animation(.easeInOut(duration: 0.3), value: showUpdateBanner)
        .onReceive(updateChecker.$updateAvailable) { available in
            if available {
                showUpdateBanner = true
            }
        }
    }
}

// Update banner view for bottom position
struct UpdateBannerView: View {
    @Binding var showBanner: Bool
    let latestVersion: String
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Update Available")
                    .font(.caption.bold())
                Text("Version \(latestVersion) is available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("View") {
                // Open release notes for the specific version
                if let url = URL(string: updateChecker.releaseURL), !updateChecker.releaseURL.isEmpty {
                    NSWorkspace.shared.open(url)
                } else {
                    // Fallback to releases page if no specific URL available
                    if let url = URL(string: "https://github.com/dilee/zen-dev-toolkit/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .buttonStyle(.borderless)
            .font(.caption)
            
            Button {
                withAnimation {
                    showBanner = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.75))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

struct CompactToolButton: View {
    let icon: String
    let title: String
    let tag: String
    @Binding var selection: String
    
    var isSelected: Bool {
        selection == tag
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = tag
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .symbolRenderingMode(.monochrome)
                    .frame(height: 20)
                Text(title)
                    .font(.system(size: 9, weight: .medium))
            }
            .frame(maxWidth: .infinity)
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

// JSONFormatterView is imported from its own file
// Base64View is imported from its own file  
// URLEncoderView is imported from its own file
// HashGeneratorView is imported from its own file
// UUIDGeneratorView is imported from its own file
// TimestampConverterView is imported from its own file
// JWTView is imported from its own file

#Preview {
    ContentView()
}
