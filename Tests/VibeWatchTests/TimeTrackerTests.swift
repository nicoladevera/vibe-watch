//
//  TimeTrackerTests.swift
//  VibeWatchTests
//
//  Unit and integration tests for TimeTracker
//

import XCTest
@testable import VibeWatch

final class TimeTrackerTests: XCTestCase {
    var tracker: TimeTracker!
    var settings: AppSettings!
    var dataStore: DataStore!
    var tempDatabaseURL: URL!
    let testSuiteName = "TestDefaults"

    override func setUp() {
        super.setUp()

        // Create test UserDefaults
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        settings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)

        // Create test DataStore
        let tempDir = FileManager.default.temporaryDirectory
        tempDatabaseURL = tempDir.appendingPathComponent("test-\(UUID().uuidString).sqlite")
        dataStore = DataStore(databasePath: tempDatabaseURL.path)

        // Create tracker with test configuration
        tracker = TimeTracker(
            settings: settings,
            dataStore: dataStore,
            pollingInterval: 0.1,   // 100ms for fast tests
            saveThreshold: 1,       // 1 second for fast tests
            dbInitDelay: 0.0        // No delay in tests
        )
    }

    override func tearDown() {
        tracker?.stopTracking()
        try? FileManager.default.removeItem(at: tempDatabaseURL)
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        tracker = nil
        dataStore = nil
        settings = nil
        tempDatabaseURL = nil
        super.tearDown()
    }

    // MARK: - Existing Basic Tests

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

    // MARK: - DataStore Integration Tests

    func testDataStoreInitialization() throws {
        // Given: Tracker initialized with DataStore

        // Then: Database should be ready immediately
        XCTAssertTrue(tracker.isDatabaseReady)
    }

    func testSaveToDataStore() throws {
        // Given: Record with some time saved directly to DataStore
        tracker.todayRecord.addTotalTime(seconds: 3600, hour: 10)
        tracker.todayRecord.addAppTime(appName: "Xcode", seconds: 3600)

        // When: Manually saving to DataStore
        try dataStore.saveDailyRecord(tracker.todayRecord)

        // Then: Record should be persisted to DataStore
        let loaded = try dataStore.fetchTodayRecord()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalSeconds, 3600)
        XCTAssertEqual(loaded?.appBreakdown["Xcode"], 3600)
    }

    func testLoadFromDataStore() throws {
        // Given: A record saved in DataStore for today (normalized to start of day)
        let today = Calendar.current.startOfDay(for: Date())
        var savedRecord = DailyRecord(date: today)
        savedRecord.addTotalTime(seconds: 7200, hour: 14)
        savedRecord.addAppTime(appName: "Safari", seconds: 7200)
        try dataStore.saveDailyRecord(savedRecord)

        // When: Creating a new tracker (should load existing data)
        let newTracker = TimeTracker(
            settings: settings,
            dataStore: dataStore,
            pollingInterval: 0.1,
            saveThreshold: 1,
            dbInitDelay: 0.0
        )

        // Wait for async load to complete (loadTodayRecord uses DispatchQueue.main.async)
        let expectation = self.expectation(description: "Record loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: Today's record should be loaded
        XCTAssertEqual(newTracker.todayRecord.totalSeconds, 7200)
        XCTAssertEqual(newTracker.todayRecord.appBreakdown["Safari"], 7200)
    }

    func testGetRecentRecords() throws {
        // Given: Multiple historical records
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        var record1 = DailyRecord(date: twoDaysAgo)
        record1.addTotalTime(seconds: 1800, hour: 10)
        var record2 = DailyRecord(date: yesterday)
        record2.addTotalTime(seconds: 3600, hour: 10)

        try dataStore.saveDailyRecord(record1)
        try dataStore.saveDailyRecord(record2)

        // When: Fetching recent records
        let records = tracker.getRecentRecords(days: 3)

        // Then: Should return historical records
        XCTAssertGreaterThanOrEqual(records.count, 2)
    }

    func testExportData() throws {
        // Given: Some tracked data
        var record = DailyRecord(date: Date())
        record.addTotalTime(seconds: 5400, hour: 11)
        record.addAppTime(appName: "Terminal", seconds: 5400)
        try dataStore.saveDailyRecord(record)

        // When: Exporting as JSON
        let jsonData = try tracker.exportData(format: .json) as! Data
        let decoded = try JSONDecoder().decode([DailyRecord].self, from: jsonData)

        // Then: Export should contain the record
        XCTAssertGreaterThanOrEqual(decoded.count, 1)

        // When: Exporting as CSV
        let csvString = try tracker.exportData(format: .csv) as! String

        // Then: CSV should have content
        XCTAssertTrue(csvString.contains("Date"))
        XCTAssertTrue(csvString.contains("Total Minutes"))
    }

    // MARK: - Pending Time Accumulation Tests

    // Note: These tests are limited because we can't easily trigger the internal
    // checkAndTrackTime() method or simulate app detection without mocking

    func testSaveOnStopTracking() throws {
        // Given: Tracker with some data saved to DataStore first
        tracker.todayRecord.addTotalTime(seconds: 1200, hour: 9)
        tracker.todayRecord.addAppTime(appName: "Cursor", seconds: 1200)
        try dataStore.saveDailyRecord(tracker.todayRecord)

        // When: Stopping tracking
        tracker.stopTracking()

        // Then: Data should still be in DataStore (stopTracking saves if pendingTime not empty)
        let loaded = try dataStore.fetchTodayRecord()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalSeconds, 1200)
    }

    // MARK: - Auto-Save Threshold Tests

    func testConfigurableSaveThreshold() throws {
        // Given: Tracker with 1-second save threshold

        // Then: Threshold should be set correctly
        XCTAssertEqual(tracker.saveThreshold, 1)
    }

    func testConfigurablePollingInterval() throws {
        // Given: Tracker with 0.1-second polling interval

        // Then: Interval should be set correctly
        XCTAssertEqual(tracker.pollingInterval, 0.1)
    }

    // MARK: - Icon State Tests

    func testIconStateWithDifferentRemainingTime() throws {
        // Given: Different scenarios

        // Scenario 1: Plenty of time remaining (>1 hour)
        tracker.todayRecord.totalSeconds = 0
        XCTAssertEqual(tracker.getIconState(), .alert)

        // Scenario 2: Less than 1 hour remaining
        let limit = settings.getTodayLimit()
        tracker.todayRecord.totalSeconds = limit - 1800  // 30 minutes remaining
        XCTAssertEqual(tracker.getIconState(), .concerned)

        // Scenario 3: Over limit
        tracker.todayRecord.totalSeconds = limit + 100
        XCTAssertEqual(tracker.getIconState(), .exhausted)
    }

    // MARK: - Settings Integration Tests

    func testTimeRemainingWithCustomLimit() throws {
        // Given: Custom daily limit
        let customLimit = 7200  // 2 hours
        settings.setLimit(for: Calendar.current.component(.weekday, from: Date()), seconds: customLimit)

        // When: Adding some time
        tracker.todayRecord.totalSeconds = 3600  // 1 hour used

        // Then: Remaining should be correct
        let remaining = tracker.getTimeRemaining()
        XCTAssertEqual(remaining, 3600)  // 1 hour remaining
    }

    func testIsOverLimitWithCustomLimit() throws {
        // Given: Custom daily limit
        let customLimit = 3600  // 1 hour
        settings.setLimit(for: Calendar.current.component(.weekday, from: Date()), seconds: customLimit)

        // When: Below limit
        tracker.todayRecord.totalSeconds = 1800
        XCTAssertFalse(tracker.isOverLimit())

        // When: Over limit
        tracker.todayRecord.totalSeconds = 3601
        XCTAssertTrue(tracker.isOverLimit())
    }

    // MARK: - Update Methods Tests

    func testUpdateIdleThreshold() throws {
        // When: Updating idle threshold
        tracker.updateIdleThreshold(seconds: 300)

        // Then: Should not crash (internal state updated)
        XCTAssertNotNil(tracker)
    }

    func testUpdateTrackedApps() throws {
        // When: Updating tracked apps
        tracker.updateTrackedApps(["Xcode", "Safari", "Chrome"])

        // Then: Should not crash (internal state updated)
        XCTAssertNotNil(tracker)
    }

    // MARK: - Clear Data Tests

    func testClearAllData() throws {
        // Given: Some historical data
        var record = DailyRecord(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        record.addTotalTime(seconds: 3600, hour: 10)
        try dataStore.saveDailyRecord(record)

        // When: Clearing all data
        try tracker.clearAllData()

        // Then: All records should be deleted
        let records = try dataStore.fetchRecentRecords(days: 7)
        XCTAssertEqual(records.count, 0)

        // And: Today's record should be reset
        XCTAssertEqual(tracker.todayRecord.totalSeconds, 0)
    }

    // MARK: - Error Handling Tests

    func testExportDataWithoutDatabase() throws {
        // Given: Tracker without database (should not happen with our test setup)
        // We can't easily test this without creating a tracker without DataStore
        // and waiting for async init, which is not practical

        // This test is more of a documentation that the error case exists
        // The actual error handling is in the exportData method
    }

    // MARK: - Time Calculation Tests

    func testTimeRemainingNeverNegative() throws {
        // Given: Time over limit
        let limit = settings.getTodayLimit()
        tracker.todayRecord.totalSeconds = limit + 7200

        // When: Getting remaining time
        let remaining = tracker.getTimeRemaining()

        // Then: Should return 0, not negative
        XCTAssertEqual(remaining, 0)
    }
}
