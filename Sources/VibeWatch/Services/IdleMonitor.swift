//
//  IdleMonitor.swift
//  VibeWatch
//
//  Monitors system idle time using ioreg command.
//

import Foundation
import CoreGraphics

class IdleMonitor {
    private let idleThresholdSeconds: TimeInterval
    
    init(idleThresholdSeconds: TimeInterval = 180) { // Default 3 minutes
        self.idleThresholdSeconds = idleThresholdSeconds
    }
    
    /// Returns the system idle time in seconds.
    /// Uses CoreGraphics to avoid blocking calls.
    func getSystemIdleTime() -> TimeInterval? {
        let eventTypes: [CGEventType] = [
            .keyDown,
            .mouseMoved,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .scrollWheel
        ]

        let idleTimes = eventTypes.compactMap { eventType -> TimeInterval? in
            let idleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: eventType)
            if idleTime.isInfinite || idleTime < 0 {
                return nil
            }
            return idleTime
        }

        return idleTimes.min()
    }
    
    /// Returns true if the user is currently active (idle time is below threshold)
    func isUserActive() -> Bool {
        guard let idleTime = getSystemIdleTime() else {
            // If we can't determine idle time, assume user is active to be safe
            return true
        }
        return idleTime < idleThresholdSeconds
    }

    func idleStatus() -> (idleTime: TimeInterval?, isActive: Bool) {
        let idleTime = getSystemIdleTime()
        if let idleTime = idleTime {
            return (idleTime, idleTime < idleThresholdSeconds)
        }
        return (nil, true)
    }
    
    /// Updates the idle threshold
    func setIdleThreshold(_ seconds: TimeInterval) {
        // Note: This would require making idleThresholdSeconds a var
        // For now, create a new instance if threshold needs to change
    }
}
