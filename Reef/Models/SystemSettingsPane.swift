//
//  SystemSettingsPane.swift
//  Reef
//
//  Deep links into System Settings privacy panes.
//

import AppKit

enum SystemSettingsPane: String {
    case accessibility = "Privacy_Accessibility"
    case screenRecording = "Privacy_ScreenCapture"

    func open() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(rawValue)")!
        NSWorkspace.shared.open(url)
    }
}
