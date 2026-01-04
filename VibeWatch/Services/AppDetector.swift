//
//  AppDetector.swift
//  VibeWatch
//
//  Detects if tracked coding applications are currently running.
//

import Foundation
import AppKit

class AppDetector {
    // Apps we're tracking
    private var trackedApps: [String]
    private let aliasBundleIdentifiers: [String: [String]] = [
        "cursor": ["com.todesktop.230313mzl4w4u92"],
        "terminal": ["com.apple.terminal"]
    ]

    init(trackedApps: [String] = ["Cursor", "Antigravity", "Terminal"]) {
        self.trackedApps = trackedApps
    }

    func updateTrackedApps(_ apps: [String]) {
        trackedApps = apps
    }
    
    /// Returns a dictionary of which tracked apps are currently running
    /// Key: app name, Value: true if running
    func detectRunningApps() -> [String: Bool] {
        var runningStatus: [String: Bool] = [:]
        
        let runningApps = NSWorkspace.shared.runningApplications
        
        for appName in trackedApps {
            let target = appName.lowercased()
            let aliases = aliasBundleIdentifiers[target] ?? []
            let isRunning = runningApps.contains { app in
                let name = app.localizedName?.lowercased() ?? ""
                let bundleId = app.bundleIdentifier?.lowercased() ?? ""
                let matchesAlias = aliases.contains { bundleId == $0 }
                return matchesAlias || name.contains(target) || bundleId.contains(target)
            }
            runningStatus[appName] = isRunning
        }
        
        return runningStatus
    }
    
    /// Returns true if at least one tracked app is running
    func isAnyTrackedAppRunning() -> Bool {
        let status = detectRunningApps()
        return status.values.contains(true)
    }
    
    /// Returns an array of currently running tracked app names
    func getRunningAppNames() -> [String] {
        let status = detectRunningApps()
        return status.filter { $0.value }.map { $0.key }
    }

    func getAllRunningAppNames() -> [String] {
        NSWorkspace.shared.runningApplications.compactMap { $0.localizedName }
    }
}
