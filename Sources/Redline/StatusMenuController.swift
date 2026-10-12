//
//  StatusMenuController.swift
//  Redline
//

import AppKit
import SwiftUI

/// Owns the menu bar item. Built with AppKit rather than `MenuBarExtra` so the status line can
/// update every second while the menu is open without rebuilding it (which closes open submenus).
@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let model = AppModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    private let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private lazy var accessItem = item("Open Automation Settings…", #selector(openAccessSettings))
    private lazy var pauseItem = NSMenuItem(title: "Pause", action: nil, keyEquivalent: "")
    private lazy var resumeItem = item("Resume", #selector(resume))
    private lazy var graceItem = NSMenuItem(title: "Glow Starts After", action: nil, keyEquivalent: "")
    private var settingsWindow: NSWindow?

    private static let pauseChoices: [(title: String, seconds: Int)] = [
        ("15 Minutes", 15 * 60), ("30 Minutes", 30 * 60), ("1 Hour", 60 * 60), ("Rest of Today", -1),
    ]

    override init() {
        super.init()
        buildMenu()
        statusItem.menu = menu
        model.onUpdate = { [weak self] in self?.refresh() }
        refresh()
    }

    // MARK: Menu

    private func buildMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(accessItem)
        menu.addItem(.separator())

        let pauseMenu = NSMenu()
        for choice in Self.pauseChoices {
            let entry = item(choice.title, #selector(pause(_:)))
            entry.tag = choice.seconds
            pauseMenu.addItem(entry)
        }
        pauseItem.submenu = pauseMenu
        menu.addItem(pauseItem)
        menu.addItem(resumeItem)

        let graceMenu = NSMenu()
        for seconds in AppSettings.graceChoices {
            let entry = item(formatGrace(seconds), #selector(setGrace(_:)))
            entry.tag = seconds
            graceMenu.addItem(entry)
        }
        graceItem.submenu = graceMenu
        menu.addItem(graceItem)
        menu.addItem(item("Preview Glow", #selector(previewGlow)))

        menu.addItem(.separator())
        menu.addItem(item("Settings…", #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(item("Quit Redline", #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    /// Updates titles and visibility in place; safe to call while the menu is open.
    private func refresh() {
        statusItem.button?.image = model.menuBarImage
        statusLine.title = model.statusText
        if case .accessDenied = model.status { accessItem.isHidden = false } else { accessItem.isHidden = true }
        pauseItem.isHidden = model.pausedUntil != nil
        resumeItem.isHidden = model.pausedUntil == nil
        for entry in graceItem.submenu?.items ?? [] {
            entry.state = entry.tag == model.settings.graceSeconds ? .on : .off
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        refresh()
    }

    // MARK: Actions

    @objc private func pause(_ sender: NSMenuItem) {
        if sender.tag < 0 {
            model.pauseForRestOfDay()
        } else {
            model.pause(for: TimeInterval(sender.tag))
        }
    }

    @objc private func resume() { model.resume() }

    @objc private func setGrace(_ sender: NSMenuItem) {
        model.settings.graceSeconds = sender.tag
        refresh()
    }

    @objc private func previewGlow() { model.previewGlow() }

    @objc private func openAccessSettings() { openAutomationSettings() }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(
                rootView: SettingsView(settings: model.settings, launchAtLogin: model.launchAtLogin)
            )
            let window = NSWindow(contentViewController: controller)
            window.title = "Redline Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    @objc private func quit() { NSApp.terminate(nil) }
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
        case .onBlockedSite:
            MenuBarIcon.alert
        case .clear, .locked:
            intensity > 0 ? MenuBarIcon.alert : MenuBarIcon.normal
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

/// "30 Seconds", "1 Minute", "5 Minutes".
func formatGrace(_ seconds: Int) -> String {
    if seconds < 60 { return "\(seconds) Seconds" }
    let minutes = seconds / 60
    return minutes == 1 ? "1 Minute" : "\(minutes) Minutes"
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded())
    return String(format: "%d:%02d", total / 60, total % 60)
}
