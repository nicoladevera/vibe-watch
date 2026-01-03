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
    private let trackedApps = ["Cursor", "Antigravity", "Terminal"]
    
    /// Returns a dictionary of which tracked apps are currently running
    /// Key: app name, Value: true if running
    func detectRunningApps() -> [String: Bool] {
        var runningStatus: [String: Bool] = [:]
        
        let runningApps = NSWorkspace.shared.runningApplications
        
        for appName in trackedApps {
            let isRunning = runningApps.contains { app in
                app.localizedName?.contains(appName) == true ||
                app.bundleIdentifier?.contains(appName.lowercased()) == true
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
}

