//
//  AppSettings.swift
//  Redline
//

import Foundation
import Observation

/// Days and times during which the alarm is armed.
struct WorkSchedule: Codable, Equatable {
    /// Calendar weekday numbers (1 = Sunday … 7 = Saturday).
    var weekdays: Set<Int>
    /// Minutes after midnight.
    var startMinutes: Int
    var endMinutes: Int

    static let standard = WorkSchedule(weekdays: [2, 3, 4, 5, 6], startMinutes: 9 * 60, endMinutes: 18 * 60)

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let weekday = parts.weekday, weekdays.contains(weekday) else { return false }
        let minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if startMinutes <= endMinutes {
            return minutes >= startMinutes && minutes < endMinutes
        }
        // Overnight shift, e.g. 22:00–06:00.
        return minutes >= startMinutes || minutes < endMinutes
    }
}

/// How many times faster built-up time drains than it accumulates once you leave a blocked site.
/// With the default 10-minute ramp, a full glow is gone in 60 s, 30 s or 10 s respectively.
enum WindDown: Int, CaseIterable, Identifiable {
    case moderate = 10
    case fast = 20
    case veryFast = 60

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .moderate: "Moderate"
        case .fast: "Fast"
        case .veryFast: "Very Fast"
        }
    }
}

/// User preferences, persisted to `UserDefaults`.
@MainActor
@Observable
final class AppSettings {
    static let defaultDomains = [
        "x.com", "twitter.com", "youtube.com", "youtu.be", "facebook.com", "instagram.com",
        "threads.net", "threads.com", "tiktok.com", "reddit.com", "linkedin.com", "pinterest.com",
        "snapchat.com", "tumblr.com", "bsky.app", "mastodon.social", "twitch.tv", "discord.com",
        "9gag.com", "vk.com", "quora.com",
    ]

    @ObservationIgnored private let defaults = UserDefaults.standard

    var domains: [String] {
        didSet { defaults.set(domains, forKey: "domains") }
    }

    /// When false the alarm is armed around the clock.
    var restrictToSchedule: Bool {
        didSet { defaults.set(restrictToSchedule, forKey: "restrictToSchedule") }
    }

    var schedule: WorkSchedule {
        didSet { defaults.set(try? JSONEncoder().encode(schedule), forKey: "schedule") }
    }

    /// Seconds on a blocked site before the glow appears.
    var graceSeconds: Int {
        didSet { defaults.set(graceSeconds, forKey: "graceSeconds") }
    }

    /// Choices offered for `graceSeconds`.
    static let graceChoices = [30, 60, 120, 180, 300, 600, 900]

    /// Minutes from the first glow until full intensity.
    var rampMinutes: Int {
        didSet { defaults.set(rampMinutes, forKey: "rampMinutes") }
    }

    var windDown: WindDown {
        didSet { defaults.set(windDown.rawValue, forKey: "windDown") }
    }

    init() {
        domains = defaults.stringArray(forKey: "domains") ?? Self.defaultDomains
        restrictToSchedule = defaults.object(forKey: "restrictToSchedule") as? Bool ?? true
        schedule = defaults.data(forKey: "schedule")
            .flatMap { try? JSONDecoder().decode(WorkSchedule.self, from: $0) } ?? .standard
        graceSeconds = defaults.object(forKey: "graceSeconds") as? Int ?? 60
        rampMinutes = defaults.object(forKey: "rampMinutes") as? Int ?? 10
        windDown = WindDown(rawValue: defaults.integer(forKey: "windDown")) ?? .fast
    }

    func isArmed(at date: Date) -> Bool {
        !restrictToSchedule || schedule.contains(date)
    }

    /// The blocked domain `url` belongs to, if any. Subdomains match their parent (m.youtube.com → youtube.com).
    func blockedDomain(for url: URL) -> String? {
        guard let host = url.host()?.lowercased() else { return nil }
        return domains.first { host == $0 || host.hasSuffix("." + $0) }
    }

    /// Adds a domain typed by the user; accepts full URLs and strips `www.`. Returns false if it was invalid.
    @discardableResult
    func addDomain(_ input: String) -> Bool {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !text.contains("://") { text = "https://" + text }
        guard var host = URL(string: text)?.host(), host.contains(".") else { return false }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        if !domains.contains(host) { domains.append(host) }
        return true
    }
}
