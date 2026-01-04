//
//  AppSettings.swift
//  VibeWatch
//
//  User settings and daily limits configuration.
//

import Foundation

class AppSettings: ObservableObject {
    @Published var dailyLimits: [Int: Int] // Day of week (1=Sun, 7=Sat) -> seconds
    @Published var idleThresholdSeconds: Int
    @Published var launchAtLogin: Bool
    @Published var showTimeInMenuBar: Bool
    @Published var trackedApps: [String]

    private let defaults: UserDefaults

    // Keys for UserDefaults
    private let dailyLimitsKey = "dailyLimits"
    private let idleThresholdKey = "idleThresholdSeconds"
    private let launchAtLoginKey = "launchAtLogin"
    private let showTimeKey = "showTimeInMenuBar"
    private let trackedAppsKey = "trackedApps"

    /// Initialize AppSettings with custom UserDefaults (for testing) or standard UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        // Load idle threshold
        let savedIdleThreshold = defaults.integer(forKey: idleThresholdKey)
        self.idleThresholdSeconds = savedIdleThreshold > 0 ? savedIdleThreshold : 180 // Default 3 minutes
        
        // Load launch at login
        self.launchAtLogin = defaults.bool(forKey: launchAtLoginKey)
        
        // Load show time in menu bar
        self.showTimeInMenuBar = defaults.bool(forKey: showTimeKey)
        
        // Load daily limits
        if let savedLimits = defaults.dictionary(forKey: dailyLimitsKey) as? [String: Int] {
            self.dailyLimits = Dictionary(uniqueKeysWithValues: savedLimits.map { (Int($0.key)!, $0.value) })
        } else {
            // Default limits: 4 hours weekdays, 2 hours weekends
            self.dailyLimits = [
                1: 2 * 3600,  // Sunday
                2: 4 * 3600,  // Monday
                3: 4 * 3600,  // Tuesday
                4: 4 * 3600,  // Wednesday
                5: 4 * 3600,  // Thursday
                6: 4 * 3600,  // Friday
                7: 2 * 3600   // Saturday
            ]
        }

        // Load tracked apps
        if let savedApps = defaults.array(forKey: trackedAppsKey) as? [String], !savedApps.isEmpty {
            self.trackedApps = savedApps
        } else {
            self.trackedApps = ["Cursor", "Antigravity", "Terminal"]
        }
    }
    
    /// Save settings to UserDefaults
    func save() {
        let stringKeyLimits = Dictionary(uniqueKeysWithValues: dailyLimits.map { (String($0.key), $0.value) })
        defaults.set(stringKeyLimits, forKey: dailyLimitsKey)
        defaults.set(idleThresholdSeconds, forKey: idleThresholdKey)
        defaults.set(launchAtLogin, forKey: launchAtLoginKey)
        defaults.set(showTimeInMenuBar, forKey: showTimeKey)
        defaults.set(trackedApps, forKey: trackedAppsKey)
    }
    
    /// Get limit for today in seconds
    func getTodayLimit() -> Int {
        let today = Calendar.current.component(.weekday, from: Date())
        return dailyLimits[today] ?? 4 * 3600 // Default 4 hours
    }
    
    /// Get limit for a specific day of week
    func getLimit(for dayOfWeek: Int) -> Int {
        return dailyLimits[dayOfWeek] ?? 4 * 3600
    }
    
    /// Set limit for a specific day of week
    func setLimit(for dayOfWeek: Int, seconds: Int) {
        dailyLimits[dayOfWeek] = seconds
        save()
    }
    
    /// Format seconds as hours (for UI display)
    static func secondsToHours(_ seconds: Int) -> Double {
        return Double(seconds) / 3600.0
    }
    
    /// Convert hours to seconds
    static func hoursToSeconds(_ hours: Double) -> Int {
        return Int(hours * 3600)
    }
}
