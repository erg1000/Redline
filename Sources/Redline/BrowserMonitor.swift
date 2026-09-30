//
//  BrowserMonitor.swift
//  Redline
//

import AppKit

/// What the frontmost app is showing.
enum BrowserPage {
    /// The frontmost app is not a supported browser, or it has no window open.
    case none
    case page(URL)
    /// macOS denied Automation access to the browser.
    case accessDenied(browser: String)
}

/// Reads the active tab's URL from Safari or Chrome via AppleScript.
@MainActor
final class BrowserMonitor {
    private static let sources: [String: String] = {
        let safari = "if (count of windows) > 0 then return URL of current tab of front window"
        let chrome = "if (count of windows) > 0 then return URL of active tab of front window"
        let ids = [
            "com.apple.Safari": safari,
            "com.apple.SafariTechnologyPreview": safari,
            "com.google.Chrome": chrome,
            "com.google.Chrome.beta": chrome,
            "com.google.Chrome.canary": chrome,
        ]
        return ids.reduce(into: [:]) { result, entry in
            result[entry.key] = "tell application id \"\(entry.key)\" to \(entry.value)"
        }
    }()

    private var scripts: [String: NSAppleScript] = [:]

    func frontmostPage() -> BrowserPage {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier,
              let script = script(for: bundleID)
        else { return .none }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            // -1743: the user hasn't allowed us to control this app.
            if error[NSAppleScript.errorNumber] as? Int == -1743 {
                return .accessDenied(browser: app.localizedName ?? bundleID)
            }
            return .none
        }
        guard let text = result.stringValue, let url = URL(string: text) else { return .none }
        return .page(url)
    }

    private func script(for bundleID: String) -> NSAppleScript? {
        if let script = scripts[bundleID] { return script }
        guard let source = Self.sources[bundleID], let script = NSAppleScript(source: source) else { return nil }
        script.compileAndReturnError(nil)
        scripts[bundleID] = script
        return script
    }
}

/// True while the login window or screen lock is showing.
func isScreenLocked() -> Bool {
    guard let session = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
    return session["CGSSessionScreenIsLocked"] as? Bool ?? false
}
