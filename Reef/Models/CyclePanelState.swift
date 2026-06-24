//
//  CyclePanelState.swift
//  Reef
//
//  Created by Xander Gouws on 23-01-2026.
//

import Foundation
import ApplicationServices
import AppKit
import ScreenCaptureKit

enum CyclePanelAction {
    case launchApp
    case openWindow
    case grantAccessibility

    var title: String {
        switch self {
        case .launchApp:
            return "Launch app"
        case .openWindow:
            return "Focus app"
        case .grantAccessibility:
            return "Grant Accessibility access…"
        }
    }
}

enum CyclePanelItem {
    case window(Window)
    case action(CyclePanelAction)
}

@MainActor
final class CyclePanelState: ObservableObject {
    @Published var applicationTitle: String = ""
    @Published var applicationIcon: NSImage?
    @Published var items: [CyclePanelItem] = []
    @Published var selectedIndex: Int = 0

    // Whether window previews are active (Screen Recording granted).
    // Without them, rows are compact text-only — the header already
    // carries the app icon.
    @Published var previewsEnabled = false

    // Window previews, keyed by CGWindowID. Kept across panel openings so
    // reopening shows the last known preview immediately, then refreshes.
    @Published var thumbnails: [CGWindowID: CGImage] = [:]
    private var captureTask: Task<Void, Never>?

    // Subtle, dismissible footer pointing at the Screen Recording grant.
    @Published var showsPreviewHint = false
    private static let hidePreviewHintKey = "hidePreviewHint"

    func dismissPreviewHint() {
        UserDefaults.standard.set(true, forKey: Self.hidePreviewHintKey)
        showsPreviewHint = false
    }

    // One-time hint shown the first time auto mode fires, nudging towards Preferences.
    @Published var showsAutoModeHint = false
    private static let hideAutoModeHintKey = "hideAutoModeHint"

    func dismissAutoModeHint() {
        UserDefaults.standard.set(true, forKey: Self.hideAutoModeHintKey)
        showsAutoModeHint = false
    }
    
    var windows: [Window] {
        items.compactMap { item in
            if case let .window(window) = item {
                return window
            }
            
            return nil
        }
    }
    
    var currentItem: CyclePanelItem? {
        guard !items.isEmpty, selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }
    
    var currentWindow: Window? {
        guard let currentItem else { return nil }
        
        if case let .window(window) = currentItem {
            return window
        }
        
        return nil
    }
    
    var currentAction: CyclePanelAction? {
        guard let currentItem else { return nil }
        
        if case let .action(action) = currentItem {
            return action
        }
        
        return nil
    }
    
    func setApplication(_ application: Application) {
        self.applicationTitle = application.title
        self.applicationIcon = application.icon
        self.previewsEnabled = CGPreflightScreenCaptureAccess()

        let windows = application.getWindows()
        if windows.isEmpty {
            let action: CyclePanelAction
            if application.isRunning, !AXIsProcessTrusted() {
                // Window listing fails silently without the Accessibility grant;
                // surface that instead of a misleading "Focus app" entry.
                action = .grantAccessibility
            } else {
                action = application.isRunning ? .openWindow : .launchApp
            }
            self.items = [.action(action)]
        } else {
            self.items = windows.map(CyclePanelItem.window)
            captureThumbnails(for: windows)
        }

        showsPreviewHint = !windows.isEmpty
            && !previewsEnabled
            && !UserDefaults.standard.bool(forKey: Self.hidePreviewHintKey)

        let isAutoMode = UserDefaults.standard.string(forKey: SwitcherMode.userDefaultsKey) != SwitcherMode.bindings.rawValue
        showsAutoModeHint = !windows.isEmpty
            && isAutoMode
            && !UserDefaults.standard.bool(forKey: Self.hideAutoModeHintKey)

        self.selectedIndex = 0
    }

    // Capture window previews via ScreenCaptureKit. Only runs when Screen
    // Recording access is already granted — we never trigger the system
    // prompt from the switcher itself (rows fall back to the app icon).
    private func captureThumbnails(for windows: [Window]) {
        guard previewsEnabled else { return }

        captureTask?.cancel()
        captureTask = Task { [weak self] in
            guard let content = try? await SCShareableContent
                .excludingDesktopWindows(false, onScreenWindowsOnly: false) else { return }

            for window in windows {
                guard !Task.isCancelled, let self else { return }

                guard let windowID = window.cgWindowID,
                      let scWindow = content.windows.first(where: { $0.windowID == windowID }),
                      scWindow.frame.width > 0, scWindow.frame.height > 0 else { continue }

                let filter = SCContentFilter(desktopIndependentWindow: scWindow)
                let configuration = SCStreamConfiguration()
                // Small still snapshot, 2x for Retina; preserve the window's
                // aspect ratio. Explicitly video-only: never capture audio.
                let scale = 160 / scWindow.frame.width
                configuration.width = Int(scWindow.frame.width * scale * 2)
                configuration.height = Int(scWindow.frame.height * scale * 2)
                configuration.showsCursor = false
                configuration.capturesAudio = false

                if let image = try? await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: configuration
                ) {
                    self.thumbnails[windowID] = image
                }
            }
        }
    }
    
    func cycleNext() {
        guard !items.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % items.count
    }
    
    func reset() {
        items = []
        selectedIndex = 0
        applicationTitle = ""
    }
}
