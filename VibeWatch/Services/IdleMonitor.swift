//
//  IdleMonitor.swift
//  VibeWatch
//
//  Monitors system idle time using ioreg command.
//

import Foundation

class IdleMonitor {
    private let idleThresholdSeconds: TimeInterval
    
    init(idleThresholdSeconds: TimeInterval = 180) { // Default 3 minutes
        self.idleThresholdSeconds = idleThresholdSeconds
    }
    
    /// Returns the system idle time in seconds
    /// Note: This call is synchronous and may block briefly (~0.1s)
    /// It should be called from a background thread for best performance
    func getSystemIdleTime() -> TimeInterval? {
        let task = Process()
        task.launchPath = "/usr/sbin/ioreg"
        task.arguments = ["-c", "IOHIDSystem"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()

            // Wait for completion (blocks current thread)
            // This typically takes ~50-100ms
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse HIDIdleTime from output
                // Format: "HIDIdleTime" = 123456789 (nanoseconds)
                if let match = output.range(of: "\"HIDIdleTime\"\\s*=\\s*(\\d+)", options: .regularExpression) {
                    let matchedString = String(output[match])
                    if let numberMatch = matchedString.range(of: "\\d+", options: .regularExpression) {
                        let numberString = String(matchedString[numberMatch])
                        if let nanoseconds = Double(numberString) {
                            // Convert nanoseconds to seconds
                            return nanoseconds / 1_000_000_000.0
                        }
                    }
                }
            }
        } catch {
            print("Error running ioreg: \(error)")
        }

        return nil
    }
    
    /// Returns true if the user is currently active (idle time is below threshold)
    func isUserActive() -> Bool {
        guard let idleTime = getSystemIdleTime() else {
            // If we can't determine idle time, assume user is active to be safe
            return true
        }
        return idleTime < idleThresholdSeconds
    }
    
    /// Updates the idle threshold
    func setIdleThreshold(_ seconds: TimeInterval) {
        // Note: This would require making idleThresholdSeconds a var
        // For now, create a new instance if threshold needs to change
    }
}

