//
//  IdleMonitorTests.swift
//  VibeWatchTests
//
//  Unit tests for IdleMonitor
//

import XCTest
@testable import VibeWatch

final class IdleMonitorTests: XCTestCase {
    var monitor: IdleMonitor!
    
    override func setUp() {
        super.setUp()
        monitor = IdleMonitor(idleThresholdSeconds: 180)
    }
    
    func testGetSystemIdleTime() throws {
        let idleTime = monitor.getSystemIdleTime()
        
        // Should return a time interval (could be nil if ioreg fails)
        if let time = idleTime {
            XCTAssertGreaterThanOrEqual(time, 0, "Idle time should be non-negative")
        }
    }
    
    func testIsUserActive() throws {
        let isActive = monitor.isUserActive()
        
        // Should return a boolean
        XCTAssertNotNil(isActive)
    }
    
    func testIdleThreshold() throws {
        // Test with very high threshold (user should be "active")
        let lenientMonitor = IdleMonitor(idleThresholdSeconds: 999999)
        let isActive = lenientMonitor.isUserActive()

        XCTAssertTrue(isActive, "With very high threshold, user should be considered active")
    }
}

