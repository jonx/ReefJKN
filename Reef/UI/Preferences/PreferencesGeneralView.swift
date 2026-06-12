//
//  PreferencesGeneralView.swift
//  Reef
//
//  Created by Xander Gouws on 26-01-2026.
//

import SwiftUI
import ServiceManagement
import ApplicationServices

struct PreferencesGeneralView: View {
    @EnvironmentObject var sparkleConnector: SparkleConnector
    @AppStorage("launchOnLogin") private var launchOnLogin = true
//    @AppStorage("hideMenubarIcon") private var hideMenubarIcon = false
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("defaultNumberOrder") private var defaultNumberOrder = "rightHanded"
    @AppStorage(SwitcherMode.userDefaultsKey) private var switcherMode = SwitcherMode.auto.rawValue
    
    @State private var hasAccessibilityPermission = AXIsProcessTrusted()
    @State private var hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()

    // Timer to poll for accessibility permission changes
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Form {
            // Accessibility Permission Warning
            if !hasAccessibilityPermission {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .imageScale(.large)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility Permission Required")
                            .fontWeight(.medium)
                        Text("System Settings → Privacy & Security → Accessibility")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Open Settings") {
                        openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section {
                Picker("Switcher mode", selection: $switcherMode) {
                    Text("Auto").tag(SwitcherMode.auto.rawValue)
                    Text("Bindings").tag(SwitcherMode.bindings.rawValue)
                }
                .pickerStyle(.segmented)
            } footer: {
                if switcherMode == SwitcherMode.auto.rawValue {
                    Text("Press the shortcut and the windows of whichever app is in front appear — no setup needed.")
                } else {
                    Text("Assign apps to number keys in Profiles, then jump to them from anywhere.")
                }
            }

            Section {
                Toggle("Launch ReefJKN at login", isOn: $launchOnLogin)
                    .onChange(of: launchOnLogin) { _, newValue in
                        setLaunchAtLogin(enabled: newValue)
                    }
                
//                Toggle("Hide menubar icon", isOn: $hideMenubarIcon)
                
                
                Picker("Default number order:", selection: $defaultNumberOrder) {
                    Text("Right handed (0, 9, ..., 1)").tag("rightHanded")
                    Text("Left handed (1, ..., 9, 0)").tag("leftHanded")
                }
                .pickerStyle(.menu)
            } footer: {
                Text("Number order sets the order in which numbers are displayed in the menubar")
            }

            Section {
                if hasScreenRecordingPermission {
                    LabeledContent("Window previews", value: "Enabled")
                } else {
                    HStack {
                        Text("Window previews")
                        Spacer()
                        Button("Grant Screen Recording Access…") {
                            // Deliberately avoid CGRequestScreenCaptureAccess():
                            // its system dialog has alarming "screen and audio"
                            // wording. The Settings pane is a calm toggle.
                            SystemSettingsPane.screenRecording.open()
                        }
                    }
                }
            } footer: {
                Text("The window switcher shows a small preview of each window. This requires Screen Recording access; without it, the app icon is shown instead. ReefJKN only takes still snapshots of windows — it never records video or audio.")
            }

            Section {
                Toggle("Automatically check for updates", isOn: $sparkleConnector.automaticallyChecksForUpdates)
            } footer: {
                Text("When enabled, ReefJKN checks for new versions on launch and periodically. You can always check manually from the menu bar.")
            }
        }
        .formStyle(.grouped)
        .frame(height: hasAccessibilityPermission ? 400 : 465)
        .onReceive(timer) { _ in
            // Poll for permission changes
            hasAccessibilityPermission = AXIsProcessTrusted()
            hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
        }
    }
    
    private func openAccessibilitySettings() {
        SystemSettingsPane.accessibility.open()
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
                // Revert the toggle if it failed
                DispatchQueue.main.async {
                    launchOnLogin = !enabled
                }
            }
        } else {
            // Legacy API for macOS 12 and earlier
            SMLoginItemSetEnabled(Bundle.main.bundleIdentifier! as CFString, enabled)
        }
    }
}

#Preview {
    PreferencesGeneralView()
        .environmentObject(SparkleConnector())
}
