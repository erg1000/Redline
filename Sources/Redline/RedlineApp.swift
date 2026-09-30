//
//  RedlineApp.swift
//  Redline
//

import SwiftUI

@main
struct RedlineApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            Image(nsImage: model.menuBarImage)
        }
        .menuBarExtraStyle(.menu)

        Window("Redline Settings", id: "settings") {
            SettingsView(settings: model.settings, launchAtLogin: model.launchAtLogin)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

private struct MenuContent: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(model.statusText)
        if case .accessDenied = model.status {
            Button("Open Automation Settings…") { openAutomationSettings() }
        }

        Divider()
        if model.pausedUntil != nil {
            Button("Resume") { model.resume() }
        } else {
            Menu("Pause") {
                Button("15 Minutes") { model.pause(for: 15 * 60) }
                Button("30 Minutes") { model.pause(for: 30 * 60) }
                Button("1 Hour") { model.pause(for: 60 * 60) }
                Button("Rest of Today") { model.pauseForRestOfDay() }
            }
        }
        Button("Preview Glow") { model.previewGlow() }

        Divider()
        Button("Settings…") {
            openWindow(id: "settings")
            NSApp.activate()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Redline") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}

func openAutomationSettings() {
    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
}

extension AppModel {
    var menuBarImage: NSImage {
        switch status {
        case .accessDenied:
            NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Redline needs browser access")!
        case .paused, .outsideWorkingHours:
            MenuBarIcon.dimmed
        case .clear, .locked, .onBlockedSite:
            intensity > 0 ? MenuBarIcon.glowing : MenuBarIcon.normal
        }
    }

    var statusText: String {
        switch status {
        case .paused(let until):
            return "Paused until \(until.formatted(date: .omitted, time: .shortened))"
        case .outsideWorkingHours:
            return "Outside working hours"
        case .locked:
            return "Screen locked"
        case .accessDenied(let browser):
            return "Can't read \(browser) – allow access in Settings"
        case .clear:
            return intensity > 0 ? "Glow fading…" : "All clear"
        case .onBlockedSite(let domain):
            if exposure < grace {
                return "On \(domain) · glow in \(formatDuration(grace - exposure))"
            }
            return "On \(domain) · \(formatDuration(exposure)) · \(Int(intensity * 100))% glow"
        }
    }
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded())
    return String(format: "%d:%02d", total / 60, total % 60)
}
