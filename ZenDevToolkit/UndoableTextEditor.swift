//
//  UndoableTextEditor.swift
//  ZenDevToolkit
//
//  Custom TextEditor that properly handles undo/redo in popover windows
//

import SwiftUI
import AppKit

struct UndoableTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    var onTextChange: ((String) -> Void)?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view
        textView.delegate = context.coordinator
        textView.font = font
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.backgroundColor = .clear
        textView.textColor = .labelColor
        textView.string = text
        
        // Make sure text view is editable
        textView.isEditable = true
        textView.isSelectable = true
        
        // Enable undo/redo
        textView.allowsUndo = true
        
        // Add padding to the text view
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        // Set up the scroll view with improved appearance
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true  // Auto-hide for cleaner look
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        
        // Use overlay style for modern, less intrusive scrollbars
        scrollView.scrollerStyle = .overlay
        scrollView.scrollerKnobStyle = .light  // Light knob for better visibility in dark mode
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if text actually changed to preserve undo stack
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: UndoableTextEditor
        
        init(_ parent: UndoableTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.onTextChange?(textView.string)
        }
    }
}

// SwiftUI modifier to use our custom text editor
extension View {
    func undoableTextEditor() -> some View {
        self
            .onAppear {
                // Ensure the Edit menu is available for keyboard shortcuts
                NSApp.mainMenu?.item(withTitle: "Edit")?.submenu?.update()
            }
    }
}