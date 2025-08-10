//
//  ContentView.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTool = "JSON"
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact tool selector without scrolling
            HStack(spacing: 6) {
                CompactToolButton(icon: "curlybraces", title: "JSON", tag: "JSON", selection: $selectedTool)
                CompactToolButton(icon: "abc", title: "Base64", tag: "Base64", selection: $selectedTool)
                CompactToolButton(icon: "link", title: "URL", tag: "URL", selection: $selectedTool)
                CompactToolButton(icon: "number.square", title: "Hash", tag: "Hash", selection: $selectedTool)
                CompactToolButton(icon: "key", title: "UUID", tag: "UUID", selection: $selectedTool)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            
            // Tool content
            Group {
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
                default:
                    Text("Select a tool")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 320, idealWidth: 400, maxWidth: 600, 
               minHeight: 400, idealHeight: 520, maxHeight: 800)
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

#Preview {
    ContentView()
}