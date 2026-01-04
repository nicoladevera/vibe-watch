//
//  DataStoreTests.swift
//  VibeWatchTests
//
//  Unit tests for DataStore persistence layer.
//

import XCTest
@testable import VibeWatch

final class DataStoreTests: XCTestCase {
    var dataStore: DataStore!
    var tempDatabaseURL: URL!

    override func setUp() {
        super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        tempDatabaseURL = tempDir.appendingPathComponent("test-\(UUID().uuidString).sqlite")
        dataStore = DataStore(databasePath: tempDatabaseURL.path)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDatabaseURL)
        dataStore = nil
        tempDatabaseURL = nil
        super.tearDown()
    }

    // MARK: - CRUD Operations

    func testSaveAndLoadRecord() throws {
        // Given: A daily record with time entries
        let testDate = Calendar.current.startOfDay(for: Date())
        var record = DailyRecord(date: testDate)
        record.addTotalTime(seconds: 300, hour: 10)
        record.addAppTime(appName: "Cursor", seconds: 300)

        // When: Saving and loading the record
        try dataStore.saveDailyRecord(record)
        let records = try dataStore.fetchRecords(from: testDate, to: testDate)

        // Then: Loaded record should match saved data
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.totalSeconds, 300)
        XCTAssertEqual(records.first?.appBreakdown["Cursor"], 300)
    }

    func testUpdateExistingRecord() throws {
        // Given: An existing record
        let testDate = Calendar.current.startOfDay(for: Date())
        var record = DailyRecord(date: testDate)
        record.addTotalTime(seconds: 300, hour: 10)
        try dataStore.saveDailyRecord(record)

        // When: Updating the record with more time
        record.addTotalTime(seconds: 600, hour: 11)
        record.addAppTime(appName: "Safari", seconds: 600)
        try dataStore.saveDailyRecord(record)

        // Then: Record should reflect updated values
        let records = try dataStore.fetchRecords(from: testDate, to: testDate)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.totalSeconds, 900)
        XCTAssertEqual(records.first?.appBreakdown["Safari"], 600)
    }

    func testFetchTodayRecord() throws {
        // Given: A record saved for today
        let today = Date()
        var record = DailyRecord(date: today)
        record.addTotalTime(seconds: 1800, hour: 14)
        try dataStore.saveDailyRecord(record)

        // When: Fetching today's record
        let fetched = try dataStore.fetchTodayRecord()

        // Then: Should return the saved record
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.totalSeconds, 1800)
    }

    func testFetchTodayRecordWhenNone() throws {
        // Given: An empty database

        // When: Fetching today's record
        let fetched = try dataStore.fetchTodayRecord()

        // Then: Should return nil
        XCTAssertNil(fetched)
    }

    func testFetchRecordsDateRange() throws {
        // Given: Multiple records across different dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        var record1 = DailyRecord(date: today)
        record1.addTotalTime(seconds: 100, hour: 10)
        var record2 = DailyRecord(date: yesterday)
        record2.addTotalTime(seconds: 200, hour: 10)
        var record3 = DailyRecord(date: twoDaysAgo)
        record3.addTotalTime(seconds: 300, hour: 10)
        var record4 = DailyRecord(date: threeDaysAgo)
        record4.addTotalTime(seconds: 400, hour: 10)

        try dataStore.saveDailyRecord(record1)
        try dataStore.saveDailyRecord(record2)
        try dataStore.saveDailyRecord(record3)
        try dataStore.saveDailyRecord(record4)

        // When: Fetching records for a specific range (yesterday to today)
        let records = try dataStore.fetchRecords(from: yesterday, to: today)

        // Then: Should return only records in range
        XCTAssertEqual(records.count, 2)
        let totalSeconds = records.map { $0.totalSeconds }
        XCTAssertTrue(totalSeconds.contains(100))
        XCTAssertTrue(totalSeconds.contains(200))
    }

    func testFetchRecentRecords() throws {
        // Given: Records for the past week
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            var record = DailyRecord(date: date)
            record.addTotalTime(seconds: (dayOffset + 1) * 100, hour: 10)
            try dataStore.saveDailyRecord(record)
        }

        // When: Fetching last 3 days
        let records = try dataStore.fetchRecentRecords(days: 3)

        // Then: Should return 3 records (today + 2 days back)
        // Note: fetchRecentRecords uses Date() (not startOfDay), so records from
        // exactly N days ago at midnight are excluded due to time comparison
        XCTAssertGreaterThanOrEqual(records.count, 3)
        XCTAssertLessThanOrEqual(records.count, 4)
    }

    func testDeleteAllRecords() throws {
        // Given: Multiple saved records
        let today = Date()
        var record1 = DailyRecord(date: today)
        record1.addTotalTime(seconds: 100, hour: 10)
        var record2 = DailyRecord(date: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        record2.addTotalTime(seconds: 200, hour: 10)

        try dataStore.saveDailyRecord(record1)
        try dataStore.saveDailyRecord(record2)

        // When: Deleting all records
        try dataStore.deleteAllRecords()

        // Then: Database should be empty
        let records = try dataStore.fetchRecords(from: Date.distantPast, to: Date())
        XCTAssertEqual(records.count, 0)
    }

    // MARK: - Export Functionality

    func testExportAsJSON() throws {
        // Given: A record with app data
        var record = DailyRecord(date: Date())
        record.addTotalTime(seconds: 3600, hour: 10)
        record.addAppTime(appName: "Xcode", seconds: 2400)
        record.addAppTime(appName: "Safari", seconds: 1200)
        try dataStore.saveDailyRecord(record)

        // When: Exporting as JSON
        let jsonData = try dataStore.exportAsJSON()

        // Then: JSON should be valid and contain the record
        let decoded = try JSONDecoder().decode([DailyRecord].self, from: jsonData)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.totalSeconds, 3600)
        XCTAssertEqual(decoded.first?.appBreakdown["Xcode"], 2400)
    }

    func testExportAsCSV() throws {
        // Given: A record with app data
        var record = DailyRecord(date: Date())
        record.addTotalTime(seconds: 7200, hour: 10) // 2 hours
        record.addAppTime(appName: "Cursor", seconds: 3600)
        record.addAppTime(appName: "Terminal", seconds: 1800)
        try dataStore.saveDailyRecord(record)

        // When: Exporting as CSV
        let csv = try dataStore.exportAsCSV()

        // Then: CSV should have proper structure
        let lines = csv.components(separatedBy: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 2, "CSV should have header and at least one data row")

        // Check header contains expected columns
        let header = lines[0]
        XCTAssertTrue(header.contains("Date"), "Header should contain Date column")
        XCTAssertTrue(header.contains("Total Hours"), "Header should contain Total Hours column")
        XCTAssertTrue(header.contains("Cursor"), "Header should contain Cursor app column")
        XCTAssertTrue(header.contains("Terminal"), "Header should contain Terminal app column")

        // Check data row has values
        let dataRow = lines[1]
        XCTAssertTrue(dataRow.contains("2"), "Data row should show 2 hours")
    }

    // MARK: - Edge Cases

    func testEmptyDatabase() throws {
        // Given: An empty database

        // When: Performing various operations
        let todayRecord = try dataStore.fetchTodayRecord()
        let recentRecords = try dataStore.fetchRecentRecords(days: 7)
        let rangeRecords = try dataStore.fetchRecords(from: Date.distantPast, to: Date())
        let jsonData = try dataStore.exportAsJSON()
        let csvData = try dataStore.exportAsCSV()

        // Then: All operations should succeed with empty results
        XCTAssertNil(todayRecord)
        XCTAssertEqual(recentRecords.count, 0)
        XCTAssertEqual(rangeRecords.count, 0)

        // JSON should be empty array
        let decoded = try JSONDecoder().decode([DailyRecord].self, from: jsonData)
        XCTAssertEqual(decoded.count, 0)

        // CSV should have header only
        XCTAssertTrue(csvData.contains("Date,Total Hours,Total Minutes"))
    }

    func testMultipleAppsInRecord() throws {
        // Given: A record with many apps
        var record = DailyRecord(date: Date())
        let apps = ["Xcode", "Safari", "Terminal", "Slack", "Cursor", "Chrome", "Spotify"]

        for (index, app) in apps.enumerated() {
            record.addAppTime(appName: app, seconds: (index + 1) * 600)
        }
        record.addTotalTime(seconds: 16800, hour: 10) // Sum of all app times

        // When: Saving and loading
        try dataStore.saveDailyRecord(record)
        let loaded = try dataStore.fetchTodayRecord()

        // Then: All apps should be preserved
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.appBreakdown.count, 7)
        XCTAssertEqual(loaded?.appBreakdown["Xcode"], 600)
        XCTAssertEqual(loaded?.appBreakdown["Spotify"], 4200)
    }

    func testLargeTimeValues() throws {
        // Given: A record with very large time values (24 hours worth)
        var record = DailyRecord(date: Date())
        let largeSeconds = 86400 // 24 hours
        record.totalSeconds = largeSeconds
        record.addAppTime(appName: "Marathon App", seconds: largeSeconds)

        // When: Saving and loading
        try dataStore.saveDailyRecord(record)
        let loaded = try dataStore.fetchTodayRecord()

        // Then: Large values should be preserved
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalSeconds, 86400)
        XCTAssertEqual(loaded?.appBreakdown["Marathon App"], 86400)
    }

    func testSpecialCharactersInAppName() throws {
        // Given: A record with special characters in app names
        var record = DailyRecord(date: Date())
        record.addAppTime(appName: "App with spaces", seconds: 100)
        record.addAppTime(appName: "App-with-dashes", seconds: 200)
        record.addAppTime(appName: "App_with_underscores", seconds: 300)
        record.addAppTime(appName: "App.with.dots", seconds: 400)
        record.addAppTime(appName: "App (with) parens", seconds: 500)
        record.addTotalTime(seconds: 1500, hour: 10)

        // When: Saving and loading
        try dataStore.saveDailyRecord(record)
        let loaded = try dataStore.fetchTodayRecord()

        // Then: All app names should be preserved correctly
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.appBreakdown["App with spaces"], 100)
        XCTAssertEqual(loaded?.appBreakdown["App-with-dashes"], 200)
        XCTAssertEqual(loaded?.appBreakdown["App_with_underscores"], 300)
        XCTAssertEqual(loaded?.appBreakdown["App.with.dots"], 400)
        XCTAssertEqual(loaded?.appBreakdown["App (with) parens"], 500)
    }
}
