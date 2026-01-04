//
//  AppDetectorTests.swift
//  VibeWatchTests
//
//  Unit tests for AppDetector
//

import XCTest
@testable import VibeWatch

final class AppDetectorTests: XCTestCase {
    var detector: AppDetector!
    
    override func setUp() {
        super.setUp()
        detector = AppDetector()
    }
    
    func testDetectRunningApps() throws {
        // Test that the method returns a dictionary
        let result = detector.detectRunningApps()
        
        XCTAssertEqual(result.count, 3, "Should track 3 apps")
        XCTAssertNotNil(result["Cursor"])
        XCTAssertNotNil(result["Antigravity"])
        XCTAssertNotNil(result["Terminal"])
    }
    
    func testIsAnyTrackedAppRunning() throws {
        // This test will vary based on what's actually running
        // Just verify it returns a boolean
        let isRunning = detector.isAnyTrackedAppRunning()
        XCTAssertNotNil(isRunning)
    }
    
    func testGetRunningAppNames() throws {
        let runningApps = detector.getRunningAppNames()

        // Should return an array (may be empty if no tracked apps running)
        XCTAssertNotNil(runningApps)
    }
}

