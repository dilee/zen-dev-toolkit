//
//  VisualEffectBackground.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2026-07-22.
//

import SwiftUI
import AppKit

// Blurred backdrop matching native menu bar popovers. state is forced to
// .active so the blur doesn't flatten while the nonactivating panel is
// not the key window.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}
