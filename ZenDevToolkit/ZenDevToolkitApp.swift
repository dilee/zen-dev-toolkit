//
//  ZenDevToolkitApp.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2025-08-10.
//

import SwiftUI

@main
struct DevToolkitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// Custom panel that can appear above fullscreen apps
class ToolkitPanel: NSPanel {
    weak var appDelegate: AppDelegate?
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    // Override resignKey to handle window closing when it loses focus
    // This approach is App Store compliant - no global event monitoring needed
    // Note: We only use this when not using auto-updater to maintain compatibility
    override func resignKey() {
        super.resignKey()
        
        #if DISABLE_AUTO_UPDATE
        // For App Store version: Close window when it loses key status
        self.orderOut(nil)
        #endif
        // For Homebrew version: Keep using event monitor for better control
    }
    
    // Ensure the panel can receive keyboard events
    override var acceptsMouseMovedEvents: Bool {
        get { true }
        set { }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    private var window: NSPanel?
    
    #if !DISABLE_AUTO_UPDATE
    private var eventMonitor: Any?
    private let updateChecker = UpdateChecker.shared
    #endif
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupWindow()
        
        #if !DISABLE_AUTO_UPDATE
        setupEventMonitor()
        
        // Check for updates in the background
        Task {
            await updateChecker.checkForUpdates()
        }
        #endif
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: "Dev Toolkit")
            button.action = #selector(handleMenuBarClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }
    
    private func setupWindow() {
        // Create a custom panel that can appear above fullscreen apps
        let panel = ToolkitPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 680),
            styleMask: [.borderless, .fullSizeContentView, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.appDelegate = self
        window = panel
        
        if let window = window {
            window.contentViewController = NSHostingController(rootView: ContentView())
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            
            // Use status bar level - same as menu bar items
            // This ensures reliable positioning above normal windows without being too aggressive
            window.level = .statusBar
            
            // Critical collection behaviors (following Maccy's proven pattern):
            // - auxiliary: Marks as auxiliary window that doesn't interfere with normal apps
            // - stationary: Prevents automatic management by Spaces
            // - moveToActiveSpace: Follows to the active Space
            // - fullScreenAuxiliary: Appears over full-screen applications
            window.collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]
            
            // Floating panel settings - key for staying on top
            window.isFloatingPanel = true
            
            // Window positioning and behavior
            window.isMovableByWindowBackground = false
            window.isReleasedWhenClosed = false
            
            // Don't hide when losing key status - critical for visibility
            window.hidesOnDeactivate = false
            
            // Allow the window to become key for input
            window.becomesKeyOnlyIfNeeded = false
            
            // Ensure the window can receive events
            window.acceptsMouseMovedEvents = true
            window.ignoresMouseEvents = false
            
            // Add rounded corners
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 10
            window.contentView?.layer?.masksToBounds = true
        }
    }
    
    @objc private func handleMenuBarClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            toggleWindow()
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "ZenDevToolkit", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        #if !DISABLE_AUTO_UPDATE
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)
        #endif
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func showAbout() {
        // Activate the app to ensure it's in the foreground
        NSApp.activate(ignoringOtherApps: true)
        
        // Show the standard About panel
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    #if !DISABLE_AUTO_UPDATE
    @objc private func checkForUpdates() {
        Task {
            await updateChecker.checkForUpdates(force: true)
            
            await MainActor.run {
                if updateChecker.updateAvailable {
                    showUpdateAlert()
                } else {
                    showNoUpdateAlert()
                }
            }
        }
    }
    
    private func showUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        
        // Different message based on installation method
        if updateChecker.isHomebrewInstall {
            alert.informativeText = """
                ZenDevToolkit \(updateChecker.latestVersion) is available. You have \(updateChecker.currentVersion).
                
                To update, run:
                brew upgrade zen-dev-toolkit
                """
            alert.addButton(withTitle: "View Release Notes")
            alert.addButton(withTitle: "Copy Command")
            alert.addButton(withTitle: "Skip This Version")
            alert.addButton(withTitle: "Remind Me Later")
        } else {
            alert.informativeText = """
                ZenDevToolkit \(updateChecker.latestVersion) is available. You have \(updateChecker.currentVersion).
                
                Download the latest version from GitHub.
                """
            alert.addButton(withTitle: "Download Update")
            alert.addButton(withTitle: "Skip This Version")
            alert.addButton(withTitle: "Remind Me Later")
        }
        
        alert.alertStyle = .informational
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        
        if updateChecker.isHomebrewInstall {
            switch response {
            case .alertFirstButtonReturn:
                updateChecker.openReleaseNotes()
            case .alertSecondButtonReturn:
                // Copy brew command to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("brew upgrade zen-dev-toolkit", forType: .string)
            case .alertThirdButtonReturn:
                updateChecker.skipThisVersion()
            default:
                break
            }
        } else {
            switch response {
            case .alertFirstButtonReturn:
                updateChecker.openReleaseNotes()
            case .alertSecondButtonReturn:
                updateChecker.skipThisVersion()
            default:
                break
            }
        }
    }
    
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're up to date!"
        alert.informativeText = "ZenDevToolkit \(updateChecker.currentVersion) is the latest version."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    #endif  // !DISABLE_AUTO_UPDATE
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func toggleWindow() {
        if let window = window, window.isVisible {
            closeWindow()
        } else {
            showWindow()
        }
    }
    
    private func showWindow() {
        guard let button = statusItem?.button,
              let buttonWindow = button.window,
              let window = window else { return }
        
        // Calculate position - directly below the menu bar button
        let buttonFrame = buttonWindow.convertToScreen(button.frame)
        let x = buttonFrame.midX - 210  // Center under button
        let y = buttonFrame.minY - window.frame.height  // Position below menu bar
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Set window level to status bar level (matching Maccy's approach)
        window.level = .statusBar
        
        // Reapply collection behaviors to ensure proper behavior
        window.collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]
        
        // Order front regardless - forces window to front regardless of which app is active
        window.orderFrontRegardless()
        
        // Make the window key to receive keyboard input
        window.makeKey()
        
        // Activate our app to ensure proper focus handling
        NSApp.activate(ignoringOtherApps: true)
        
        // Make the first text field the first responder
        DispatchQueue.main.async {
            window.makeFirstResponder(window.contentView)
        }
    }
    
    private func closeWindow() {
        window?.orderOut(nil)
    }
    
    #if !DISABLE_AUTO_UPDATE
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let window = self?.window, window.isVisible {
                let mouseLocation = NSEvent.mouseLocation
                if !window.frame.contains(mouseLocation) {
                    // Check if click is not on the status item
                    if let button = self?.statusItem?.button,
                       let buttonWindow = button.window {
                        let buttonFrame = buttonWindow.convertToScreen(button.frame)
                        if !buttonFrame.contains(mouseLocation) {
                            self?.closeWindow()
                        }
                    } else {
                        self?.closeWindow()
                    }
                }
            }
        }
    }
    
    deinit {
        #if !DISABLE_AUTO_UPDATE
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        #endif
    }
    #endif  // !DISABLE_AUTO_UPDATE
}
