//
//  SettingsView.swift
//  VibeWatch
//
//  Settings window for configuring daily limits and preferences.
//

import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var settings: AppSettings
    var onDone: () -> Void
    @State private var newTrackedApp = ""
    
    private let daysOfWeek = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    settings.save()
                    onDone()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Daily Limits Section
                    dailyLimitsSection
                    
                    Divider()

                    // Tracked Apps Section
                    trackedAppsSection
                    
                    Divider()
                    
                    // Preferences Section
                    preferencesSection
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private var dailyLimitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Coding Limits")
                .font(.headline)
            
            Text("Set how many hours you want to code each day. Limits are in 15-minute increments.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(daysOfWeek, id: \.0) { day in
                DayLimitSlider(
                    dayName: day.1,
                    dayNumber: day.0,
                    settings: settings
                )
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)
            
            // Idle threshold
            VStack(alignment: .leading, spacing: 8) {
                Text("Idle Threshold: \(settings.idleThresholdSeconds / 60) minutes")
                    .font(.subheadline)
                
                Slider(
                    value: Binding(
                        get: { Double(settings.idleThresholdSeconds) },
                        set: { settings.idleThresholdSeconds = Int($0) }
                    ),
                    in: 60...600,
                    step: 60
                )
                
                Text("Stop counting time after this many minutes of inactivity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Show time in menu bar
            Toggle("Show time in menu bar", isOn: $settings.showTimeInMenuBar)
            
            // Launch at login
            Toggle("Launch at login", isOn: $settings.launchAtLogin)

            Text("Launch at login may require a restart to take effect")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var trackedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracked Apps")
                .font(.headline)

            Text("Add app names as they appear in Activity Monitor.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("Add app (e.g., Xcode)", text: $newTrackedApp)
                Button("Add") {
                    addTrackedApp()
                }
                .disabled(newTrackedApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if settings.trackedApps.isEmpty {
                Text("No apps tracked yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(settings.trackedApps, id: \.self) { app in
                    HStack {
                        Text(app)
                        Spacer()
                        Button("Remove") {
                            removeTrackedApp(app)
                        }
                    }
                }
            }
        }
    }

    private func addTrackedApp() {
        let trimmed = newTrackedApp.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !settings.trackedApps.contains(trimmed) else {
            newTrackedApp = ""
            return
        }
        settings.trackedApps.append(trimmed)
        newTrackedApp = ""
    }

    private func removeTrackedApp(_ app: String) {
        settings.trackedApps.removeAll { $0 == app }
    }
}

struct DayLimitSlider: View {
    let dayName: String
    let dayNumber: Int
    @ObservedObject var settings: AppSettings
    
    private var limitHours: Binding<Double> {
        Binding(
            get: { AppSettings.secondsToHours(settings.getLimit(for: dayNumber)) },
            set: { newHours in
                // Round to nearest 0.25 (15 minutes)
                let rounded = round(newHours * 4) / 4
                settings.setLimit(for: dayNumber, seconds: AppSettings.hoursToSeconds(rounded))
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dayName)
                    .frame(width: 100, alignment: .leading)
                
                Slider(value: limitHours, in: 0...12, step: 0.25)
                
                Text(formatHours(limitHours.wrappedValue))
                    .frame(width: 60, alignment: .trailing)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
    
    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

#Preview {
    SettingsWindowView(settings: AppSettings(), onDone: {})
}
