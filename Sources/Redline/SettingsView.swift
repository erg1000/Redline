//
//  SettingsView.swift
//  Redline
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let launchAtLogin: LaunchAtLogin
    @State private var newDomain = ""
    @State private var invalidDomain = false

    /// Monday-first week, as calendar weekday numbers.
    private static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        Form {
            Section("Working Hours") {
                Toggle("Only alarm during working hours", isOn: $settings.restrictToSchedule)
                Group {
                    DatePicker("Start", selection: timeBinding(\.startMinutes), displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: timeBinding(\.endMinutes), displayedComponents: .hourAndMinute)
                    LabeledContent("Days") {
                        HStack(spacing: 4) {
                            ForEach(Self.weekdayOrder, id: \.self) { weekday in
                                Toggle(Calendar.current.shortStandaloneWeekdaySymbols[weekday - 1],
                                       isOn: weekdayBinding(weekday))
                                    .toggleStyle(.button)
                            }
                        }
                    }
                }
                .disabled(!settings.restrictToSchedule)
            }

            Section("Alarm") {
                Picker("Glow starts after", selection: $settings.graceSeconds) {
                    ForEach(AppSettings.graceChoices, id: \.self) { Text(formatGrace($0)).tag($0) }
                }
                Stepper("Full intensity \(settings.rampMinutes) min later", value: $settings.rampMinutes, in: 1...60)
                Picker("Wind-down when you leave", selection: $settings.windDown) {
                    ForEach(WindDown.allCases) { Text($0.title).tag($0) }
                }
            }

            Section {
                ForEach(settings.domains, id: \.self) { domain in
                    HStack {
                        Text(domain)
                        Spacer()
                        Button {
                            settings.domains.removeAll { $0 == domain }
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Remove \(domain)")
                    }
                }
                HStack {
                    TextField("Add a site, e.g. news.ycombinator.com", text: $newDomain)
                        .onSubmit(addDomain)
                    Button("Add", action: addDomain)
                        .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if invalidDomain {
                    Text("That doesn't look like a website address.").foregroundStyle(.red).font(.caption)
                }
            } header: {
                HStack {
                    Text("Sites")
                    Spacer()
                    Button("Restore Defaults") { settings.domains = AppSettings.defaultDomains }
                        .buttonStyle(.link)
                        .font(.caption)
                }
            } footer: {
                Text("Subdomains are included, so youtube.com also covers m.youtube.com.")
                    .foregroundStyle(.secondary)
            }

            Section("General") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                ))
                LabeledContent("Browser access") {
                    Button("Open Automation Settings…", action: openAutomationSettings)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 640)
    }

    private func addDomain() {
        invalidDomain = !settings.addDomain(newDomain)
        if !invalidDomain { newDomain = "" }
    }

    private func timeBinding(_ keyPath: WritableKeyPath<WorkSchedule, Int>) -> Binding<Date> {
        Binding {
            let minutes = settings.schedule[keyPath: keyPath]
            return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            settings.schedule[keyPath: keyPath] = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }

    private func weekdayBinding(_ weekday: Int) -> Binding<Bool> {
        Binding {
            settings.schedule.weekdays.contains(weekday)
        } set: { isOn in
            if isOn {
                settings.schedule.weekdays.insert(weekday)
            } else {
                settings.schedule.weekdays.remove(weekday)
            }
        }
    }
}
