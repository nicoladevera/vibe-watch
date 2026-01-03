//
//  TimeTrackerTests.swift
//  VibeWatchTests
//
//  Unit tests for TimeTracker
//

import XCTest
@testable import VibeWatch

final class TimeTrackerTests: XCTestCase {
    var tracker: TimeTracker!
    var settings: AppSettings!
    
    override func setUp() {
        super.setUp()
        settings = AppSettings()
        tracker = TimeTracker(settings: settings)
    }
    
    func testInitialization() throws {
        XCTAssertNotNil(tracker.todayRecord)
        XCTAssertFalse(tracker.isTracking)
        XCTAssertEqual(tracker.todayRecord.totalSeconds, 0)
    }
    
    func testGetTimeRemaining() throws {
        let limit = settings.getTodayLimit()
        let remaining = tracker.getTimeRemaining()
        
        XCTAssertGreaterThanOrEqual(remaining, 0)
        XCTAssertLessThanOrEqual(remaining, limit)
    }
    
    func testGetIconState() throws {
        let state = tracker.getIconState()
        
        // Should return one of the three states
        XCTAssertTrue([IconState.alert, IconState.concerned, IconState.exhausted].contains(state))
    }
    
    func testIsOverLimit() throws {
        // Initially should not be over limit
        XCTAssertFalse(tracker.isOverLimit())
    }
    
    func testStartStopTracking() throws {
        tracker.startTracking()
        XCTAssertTrue(tracker.isTracking)
        
        tracker.stopTracking()
        XCTAssertFalse(tracker.isTracking)
    }
}

