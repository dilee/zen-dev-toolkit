//
//  HotkeyManager.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2026-07-22.
//

import Foundation
import Carbon.HIToolbox

// Global hotkey presets. Raw values double as the persisted UserDefaults token.
enum HotkeyPreset: String, CaseIterable {
    case off = "off"
    case ctrlOptSpace = "⌃⌥Space"
    case optSpace = "⌥Space"
    case ctrlOptZ = "⌃⌥Z"

    // Carbon virtual key code, or nil when disabled
    var keyCode: UInt32? {
        switch self {
        case .off:
            return nil
        case .ctrlOptSpace, .optSpace:
            return UInt32(kVK_Space)
        case .ctrlOptZ:
            return UInt32(kVK_ANSI_Z)
        }
    }

    // Carbon modifier mask
    var modifiers: UInt32 {
        switch self {
        case .off:
            return 0
        case .ctrlOptSpace, .ctrlOptZ:
            return UInt32(controlKey) | UInt32(optionKey)
        case .optSpace:
            return UInt32(optionKey)
        }
    }

    // Title shown in the menu (spaced for readability, unlike the raw value)
    var menuTitle: String {
        switch self {
        case .off:
            return "Off"
        case .ctrlOptSpace:
            return "⌃⌥ Space"
        case .optSpace:
            return "⌥ Space"
        case .ctrlOptZ:
            return "⌃⌥ Z"
        }
    }
}

// Registers a single global hotkey via the Carbon Event Manager (public API, App Store safe).
final class HotkeyManager {
    static let defaultsKey = "globalHotkeyPreset"

    // Invoked on the main thread when the hotkey fires.
    var action: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Fixed identity for our single hotkey ('ZDTK', id 1)
    private let signature: OSType = 0x5A44544B
    private let hotKeyID: UInt32 = 1

    var currentPreset: HotkeyPreset {
        get {
            let raw = UserDefaults.standard.string(forKey: Self.defaultsKey) ?? HotkeyPreset.off.rawValue
            return HotkeyPreset(rawValue: raw) ?? .off
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.defaultsKey)
            register(newValue)
        }
    }

    init() {
        installHandler()
        register(currentPreset)
    }

    deinit {
        unregister()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    // Install the shared handler once; self is threaded through userData so the
    // C callback can reach back into this instance without capturing context.
    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.action?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        if status != noErr {
            print("Failed to install global hotkey handler: \(status)")
        }
    }

    // Swap the active registration. Safe to call repeatedly; .off just unregisters.
    func register(_ preset: HotkeyPreset) {
        unregister()
        guard let keyCode = preset.keyCode else { return }

        let eventID = EventHotKeyID(signature: signature, id: hotKeyID)
        let status = RegisterEventHotKey(
            keyCode,
            preset.modifiers,
            eventID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            // A conflicting system-wide hotkey is the usual cause; stay disabled.
            print("Failed to register global hotkey \(preset.rawValue): \(status)")
            hotKeyRef = nil
        }
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}
