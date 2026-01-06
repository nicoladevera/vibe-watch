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
                // Skip helper processes and background services
                // Main apps typically have .regular activation policy
                if app.activationPolicy != .regular {
                    return false
                }
                
                let name = app.localizedName?.lowercased() ?? ""
                let bundleId = app.bundleIdentifier?.lowercased() ?? ""
                
                // Skip processes with "helper" in the name (these are helper processes, not the main app)
                if name.contains("helper") {
                    return false
                }
                
                // Check for exact bundle ID match (aliases)
                let matchesAlias = aliases.contains { bundleId == $0 }
                
                // Check for exact name match (case-insensitive)
                let exactNameMatch = name == target
                
                // Only use bundle ID substring matching if no exact matches
                // This is less reliable but needed for some apps
                let bundleIdContains = bundleId.contains(target)
                
                return matchesAlias || exactNameMatch || bundleIdContains
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
    
    /// Returns the name of the currently active/frontmost tracked app, or nil if none
    func getActiveAppName() -> String? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        // Skip helper processes - only match main apps
        if frontmostApp.activationPolicy != .regular {
            return nil
        }
        
        let frontmostName = frontmostApp.localizedName?.lowercased() ?? ""
        let frontmostBundleId = frontmostApp.bundleIdentifier?.lowercased() ?? ""
        
        // Skip helper processes
        if frontmostName.contains("helper") {
            return nil
        }
        
        // Check if the frontmost app matches any tracked app
        for appName in trackedApps {
            let target = appName.lowercased()
            let aliases = aliasBundleIdentifiers[target] ?? []
            
            let matchesAlias = aliases.contains { frontmostBundleId == $0 }
            let exactNameMatch = frontmostName == target
            let bundleIdContains = frontmostBundleId.contains(target)
            
            if matchesAlias || exactNameMatch || bundleIdContains {
                return appName
            }
        }
        
        return nil
    }
}
