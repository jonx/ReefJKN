//
//  CyclePanel.swift
//  Reef
//
//  Created by Xander Gouws on 19-01-2026.
//

import AppKit
import SwiftUI


final class CyclePanel: NSPanel, NSWindowDelegate {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.hasShadow = true
        self.level = .floating
        self.collectionBehavior.insert(.fullScreenAuxiliary)
        self.collectionBehavior.insert(.canJoinAllSpaces)
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.delegate = self
        self.backgroundColor = .clear
        self.hidesOnDeactivate = true
        
        // Native look: system popover material that follows Light/Dark mode.
        let effectView = NSVisualEffectView(frame: .zero)
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .popover
        effectView.blendingMode = .behindWindow
        effectView.state = .active

        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16
        effectView.layer?.cornerCurve = .continuous
        effectView.layer?.masksToBounds = true

        // Hairline edge so the panel reads crisply on busy backgrounds.
        effectView.layer?.borderWidth = 1
        effectView.layer?.borderColor = NSColor.separatorColor.cgColor

        self.contentView = effectView
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    func windowDidResignKey(_ notification: Notification) {
        self.orderOut(nil)
    }
}
