//
//  ShortcutController.swift
//  Reef
//
//  Created by Xander Gouws on 12-09-2025.
//

import KeyboardShortcuts
import Cocoa

let numberKeys: [KeyboardShortcuts.Key] = [
    .zero, .one, .two, .three, .four,
    .five, .six, .seven, .eight, .nine
]

extension KeyboardShortcuts.Name {
    static let bindShortcuts: [KeyboardShortcuts.Name] = (0...9).map { number in
        Self("bind\(number)")
    }

    static let activateShortcuts: [KeyboardShortcuts.Name] = (0...9).map { number in
        Self("activate\(number)")
    }

    static let profileShortcuts: [KeyboardShortcuts.Name] = (0...9).map { number in
        Self("profile\(number)")
    }

    static let moveWindowLeft  = Self("moveWindowLeft",  default: .init(.leftArrow,  modifiers: [.command, .shift]))
    static let moveWindowRight = Self("moveWindowRight", default: .init(.rightArrow, modifiers: [.command, .shift]))
}

@MainActor
final class ShortcutController {
    private let cycleController: CyclePanelController
    private let profileManager: ProfileManager
    
    init(_ cycleController: CyclePanelController, _ profileManager: ProfileManager) {
        self.cycleController = cycleController
        self.profileManager = profileManager
        
        setupShortcuts()
    }
    
    private func setupShortcuts() {
        for number in 0...9 {
            KeyboardShortcuts.onKeyUp(for: .bindShortcuts[number]) {
                self.handleBind(number: number)
            }

            KeyboardShortcuts.onKeyDown(for: .activateShortcuts[number]) {
                self.handleActivate(number: number)
            }

            KeyboardShortcuts.onKeyDown(for: .profileShortcuts[number]) {
                self.handleProfile(number: number)
            }
        }

        KeyboardShortcuts.onKeyDown(for: .moveWindowLeft)  { self.handleMoveWindow(direction: .previous) }
        KeyboardShortcuts.onKeyDown(for: .moveWindowRight) { self.handleMoveWindow(direction: .next) }
    }
    
    private func handleBind(number: Int) {
        guard let application = Application.getFrontApplication() else {
            NSSound.beep()
            return
        }

        guard let bundleIdentifier = application.bundleIdentifier else {
            NSSound.beep()
            return
        }

        profileManager.bind(bundleIdentifier: bundleIdentifier, to: number)

        print("Bound \(application.title) to \(number)")
    }
    
    private func handleActivate(number: Int) {
        let isAutoMode = UserDefaults.standard.string(forKey: SwitcherMode.userDefaultsKey) != SwitcherMode.bindings.rawValue

        if isAutoMode {
            // Panel already open — the panel itself has focus, so getFrontApplication()
            // would return ReefJKN. Just cycle to the next window instead.
            if cycleController.panel.isVisible {
                cycleController.cycleNext()
                return
            }

            guard let frontApp = Application.getFrontApplication() else {
                NSSound.beep()
                return
            }

            cycleController.showSwitcher(for: frontApp)
            return
        }

        // Bindings mode: look up the app assigned to this number key.
        guard let binding = profileManager.application(for: number) else {
            NSSound.beep()
            return
        }

        if cycleController.panel.isVisible {
            if cycleController.isShowingSwitcher(for: binding) {
                cycleController.cycleNext()
            } else {
                cycleController.showSwitcher(for: binding)
            }
            return
        }

        var startIndex = 0
        if let frontApp = Application.getFrontApplication(),
           frontApp.title == binding.title {
            startIndex = 1
        }

        cycleController.showSwitcher(for: binding, startIndex: startIndex)
    }
    
    private func handleMoveWindow(direction: ScreenDirection) {
        guard let window = Window.getFrontWindow() else {
            NSSound.beep()
            return
        }
        window.moveToAdjacentScreen(direction: direction)
    }

    func handleProfile(number: Int) {
        guard let profileID = profileManager.profileID(forNumber: number) else {
            NSSound.beep()
            return
        }
        
        profileManager.switchProfile(id: profileID)
    }
}
