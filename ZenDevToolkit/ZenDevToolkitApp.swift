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
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    private var window: NSPanel?
    private var eventMonitor: Any?
    private let updateChecker = UpdateChecker.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupWindow()
        setupEventMonitor()
        
        // Check for updates in the background
        Task {
            await updateChecker.checkForUpdates()
        }
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
        window = ToolkitPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 680),
            styleMask: [.borderless, .fullSizeContentView, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        if let window = window {
            window.contentViewController = NSHostingController(rootView: ContentView())
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            // Use a very high window level
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.assistiveTechHighWindow.rawValue))
            // Critical: Allow the window to appear in all spaces including fullscreen
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            window.isMovableByWindowBackground = false
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.isFloatingPanel = true
            window.becomesKeyOnlyIfNeeded = false
            
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
        
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)
        
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
        alert.informativeText = "ZenDevToolkit \(updateChecker.latestVersion) is available. You have \(updateChecker.currentVersion)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "View Release")
        alert.addButton(withTitle: "Skip This Version")
        alert.addButton(withTitle: "Remind Me Later")
        
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            updateChecker.openReleaseNotes()
        case .alertSecondButtonReturn:
            updateChecker.skipThisVersion()
        default:
            break
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
        
        // Ensure we're using the highest possible window level
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.assistiveTechHighWindow.rawValue))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        
        // Make the window visible and active
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        
        // Force activate our app
        NSApp.activate(ignoringOtherApps: true)
        
        // Make the first text field the first responder
        DispatchQueue.main.async {
            window.makeFirstResponder(window.contentView)
            // Force the window to the front again after a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.orderFrontRegardless()
            }
        }
    }
    
    private func closeWindow() {
        window?.orderOut(nil)
    }
    
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
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
