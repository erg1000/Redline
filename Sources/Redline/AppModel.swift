//
//  AppModel.swift
//  Redline
//

import AppKit
import OSLog
import Observation

/// What the app is currently seeing.
enum AlarmStatus: Equatable {
    case paused(until: Date)
    case outsideWorkingHours
    case locked
    case clear
    case onBlockedSite(String)
    case accessDenied(browser: String)
}

/// Polls the browser once a second, accumulates time spent on blocked sites and drives the glow.
@MainActor
@Observable
final class AppModel {
    let settings = AppSettings()
    let launchAtLogin = LaunchAtLogin()
    @ObservationIgnored private let browser = BrowserMonitor()
    @ObservationIgnored private let overlay = GlowOverlay()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastTick = Date.now
    @ObservationIgnored private var previewStart: Date?

    private(set) var status: AlarmStatus = .clear
    /// Seconds of blocked-site time built up; drains while you are elsewhere.
    private(set) var exposure: TimeInterval = 0
    private(set) var pausedUntil: Date?

    private static let previewDuration: TimeInterval = 8

    init() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.2
        // Common modes keep ticking while the menu bar menu is open (event-tracking mode).
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        if CommandLine.arguments.contains("--preview") { previewStart = .now }
        tick()
    }

    var grace: TimeInterval { TimeInterval(settings.graceSeconds) }
    var ramp: TimeInterval { TimeInterval(max(settings.rampMinutes, 1) * 60) }

    var intensity: Double {
        min(max((exposure - grace) / ramp, 0), 1)
    }

    // MARK: Actions

    func pause(for duration: TimeInterval) {
        pause(until: Date.now.addingTimeInterval(duration))
    }

    func pauseForRestOfDay() {
        let calendar = Calendar.current
        pause(until: calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!))
    }

    func resume() {
        pausedUntil = nil
        tick()
    }

    /// Sweeps the glow from nothing to full and back so you can see what it looks like.
    func previewGlow() {
        previewStart = .now
        tick()
    }

    private func pause(until date: Date) {
        pausedUntil = date
        exposure = 0
        tick()
    }

    // MARK: Polling

    private func tick() {
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastTick)
        lastTick = now

        // The Mac slept or the app stalled; don't count or carry over that gap.
        if elapsed > 30 { exposure = 0 }
        let step = min(elapsed, 30)

        let newStatus = currentStatus(at: now)
        if newStatus != status { Logger().notice("Status: \(String(describing: newStatus), privacy: .public)") }
        status = newStatus
        if case .onBlockedSite = status {
            exposure += step
        } else {
            exposure = max(0, exposure - step * Double(settings.windDown.rawValue))
        }

        if let previewStart, now.timeIntervalSince(previewStart) < Self.previewDuration {
            let progress = now.timeIntervalSince(previewStart) / Self.previewDuration
            overlay.setIntensity(progress < 0.6 ? progress / 0.6 : 1 - (progress - 0.6) / 0.4)
        } else {
            previewStart = nil
            overlay.setIntensity(intensity)
        }
    }

    private func currentStatus(at now: Date) -> AlarmStatus {
        if let pausedUntil {
            if pausedUntil > now { return .paused(until: pausedUntil) }
            self.pausedUntil = nil
        }
        guard settings.isArmed(at: now) else { return .outsideWorkingHours }
        guard !isScreenLocked() else { return .locked }

        switch browser.frontmostPage() {
        case .none:
            return .clear
        case .accessDenied(let name):
            return .accessDenied(browser: name)
        case .page(let url):
            return settings.blockedDomain(for: url).map(AlarmStatus.onBlockedSite) ?? .clear
        }
    }
}
