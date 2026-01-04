//
//  AppSettingsTests.swift
//  VibeWatchTests
//
//  Unit tests for AppSettings persistence and configuration.
//

import XCTest
@testable import VibeWatch

final class AppSettingsTests: XCTestCase {
    var settings: AppSettings!
    let testSuiteName = "TestDefaults"

    override func setUp() {
        super.setUp()
        // Use separate UserDefaults for testing
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        settings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        settings = nil
        super.tearDown()
    }

    // MARK: - Default Values Tests

    func testDefaultDailyLimits() {
        // Given: A fresh AppSettings instance

        // Then: All 7 days should have correct defaults
        // Weekdays (Mon-Fri): 4 hours = 14400 seconds
        // Weekends (Sun, Sat): 2 hours = 7200 seconds
        XCTAssertEqual(settings.dailyLimits[1], 7200, "Sunday should default to 2 hours")
        XCTAssertEqual(settings.dailyLimits[2], 14400, "Monday should default to 4 hours")
        XCTAssertEqual(settings.dailyLimits[3], 14400, "Tuesday should default to 4 hours")
        XCTAssertEqual(settings.dailyLimits[4], 14400, "Wednesday should default to 4 hours")
        XCTAssertEqual(settings.dailyLimits[5], 14400, "Thursday should default to 4 hours")
        XCTAssertEqual(settings.dailyLimits[6], 14400, "Friday should default to 4 hours")
        XCTAssertEqual(settings.dailyLimits[7], 7200, "Saturday should default to 2 hours")
    }

    func testDefaultIdleThreshold() {
        // Given: A fresh AppSettings instance

        // Then: Idle threshold should default to 180 seconds (3 minutes)
        XCTAssertEqual(settings.idleThresholdSeconds, 180)
    }

    func testDefaultLaunchAtLogin() {
        // Given: A fresh AppSettings instance

        // Then: Launch at login should default to false
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testDefaultShowTimeInMenuBar() {
        // Given: A fresh AppSettings instance

        // Then: Show time in menu bar should default to false
        XCTAssertFalse(settings.showTimeInMenuBar)
    }

    func testDefaultTrackedApps() {
        // Given: A fresh AppSettings instance

        // Then: Tracked apps should default to the predefined list
        XCTAssertEqual(settings.trackedApps.count, 3)
        XCTAssertTrue(settings.trackedApps.contains("Cursor"))
        XCTAssertTrue(settings.trackedApps.contains("Antigravity"))
        XCTAssertTrue(settings.trackedApps.contains("Terminal"))
    }

    // MARK: - Persistence Tests

    func testSaveAndLoadDailyLimits() {
        // Given: Custom limits for all days
        settings.setLimit(for: 1, seconds: 3600)   // Sunday: 1 hour
        settings.setLimit(for: 2, seconds: 7200)   // Monday: 2 hours
        settings.setLimit(for: 3, seconds: 10800)  // Tuesday: 3 hours
        settings.setLimit(for: 4, seconds: 14400)  // Wednesday: 4 hours
        settings.setLimit(for: 5, seconds: 18000)  // Thursday: 5 hours
        settings.setLimit(for: 6, seconds: 21600)  // Friday: 6 hours
        settings.setLimit(for: 7, seconds: 25200)  // Saturday: 7 hours

        // When: Creating a new settings instance with same UserDefaults
        let newSettings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)

        // Then: All limits should persist
        XCTAssertEqual(newSettings.dailyLimits[1], 3600)
        XCTAssertEqual(newSettings.dailyLimits[2], 7200)
        XCTAssertEqual(newSettings.dailyLimits[3], 10800)
        XCTAssertEqual(newSettings.dailyLimits[4], 14400)
        XCTAssertEqual(newSettings.dailyLimits[5], 18000)
        XCTAssertEqual(newSettings.dailyLimits[6], 21600)
        XCTAssertEqual(newSettings.dailyLimits[7], 25200)
    }

    func testSaveAndLoadIdleThreshold() {
        // Given: A custom idle threshold
        settings.idleThresholdSeconds = 300 // 5 minutes
        settings.save()

        // When: Creating a new settings instance
        let newSettings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)

        // Then: Idle threshold should persist
        XCTAssertEqual(newSettings.idleThresholdSeconds, 300)
    }

    func testSaveAndLoadLaunchAtLogin() {
        // Given: Launch at login enabled
        settings.launchAtLogin = true
        settings.save()

        // When: Creating a new settings instance
        let newSettings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)

        // Then: Launch at login should persist
        XCTAssertTrue(newSettings.launchAtLogin)
    }

    func testSaveAndLoadShowTimeInMenuBar() {
        // Given: Show time in menu bar enabled
        settings.showTimeInMenuBar = true
        settings.save()

        // When: Creating a new settings instance
        let newSettings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)

        // Then: Show time preference should persist
        XCTAssertTrue(newSettings.showTimeInMenuBar)
    }

    func testSaveAndLoadTrackedApps() {
        // Given: A custom list of tracked apps
        settings.trackedApps = ["Xcode", "Safari", "VS Code", "Chrome"]
        settings.save()

        // When: Creating a new settings instance
        let newSettings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)

        // Then: Tracked apps should persist
        XCTAssertEqual(newSettings.trackedApps.count, 4)
        XCTAssertTrue(newSettings.trackedApps.contains("Xcode"))
        XCTAssertTrue(newSettings.trackedApps.contains("Safari"))
        XCTAssertTrue(newSettings.trackedApps.contains("VS Code"))
        XCTAssertTrue(newSettings.trackedApps.contains("Chrome"))
    }

    // MARK: - Functionality Tests

    func testGetTodayLimit() {
        // Given: A settings instance with default limits
        let todayWeekday = Calendar.current.component(.weekday, from: Date())

        // When: Getting today's limit
        let todayLimit = settings.getTodayLimit()

        // Then: Should match the limit for today's weekday
        XCTAssertEqual(todayLimit, settings.dailyLimits[todayWeekday])
    }

    func testGetLimitForSpecificDay() {
        // Given: Default settings

        // When/Then: Getting limits for all days should match dailyLimits dictionary
        for day in 1...7 {
            let limit = settings.getLimit(for: day)
            XCTAssertEqual(limit, settings.dailyLimits[day], "Limit for day \(day) should match")
        }
    }

    func testSetLimit() {
        // Given: A specific day and limit
        let targetDay = 3 // Tuesday
        let newLimit = 9000 // 2.5 hours

        // When: Setting the limit
        settings.setLimit(for: targetDay, seconds: newLimit)

        // Then: The limit should be saved and retrievable
        XCTAssertEqual(settings.getLimit(for: targetDay), newLimit)
        XCTAssertEqual(settings.dailyLimits[targetDay], newLimit)

        // And: It should persist to a new instance
        let newSettings = AppSettings(userDefaults: UserDefaults(suiteName: testSuiteName)!)
        XCTAssertEqual(newSettings.getLimit(for: targetDay), newLimit)
    }

    func testSecondsToHoursConversion() {
        // Test various conversions
        XCTAssertEqual(AppSettings.secondsToHours(3600), 1.0, "3600 seconds = 1 hour")
        XCTAssertEqual(AppSettings.secondsToHours(7200), 2.0, "7200 seconds = 2 hours")
        XCTAssertEqual(AppSettings.secondsToHours(1800), 0.5, "1800 seconds = 0.5 hours")
        XCTAssertEqual(AppSettings.secondsToHours(0), 0.0, "0 seconds = 0 hours")
        XCTAssertEqual(AppSettings.secondsToHours(14400), 4.0, "14400 seconds = 4 hours")
    }

    func testHoursToSecondsConversion() {
        // Test various conversions
        XCTAssertEqual(AppSettings.hoursToSeconds(1.0), 3600, "1 hour = 3600 seconds")
        XCTAssertEqual(AppSettings.hoursToSeconds(2.0), 7200, "2 hours = 7200 seconds")
        XCTAssertEqual(AppSettings.hoursToSeconds(0.5), 1800, "0.5 hours = 1800 seconds")
        XCTAssertEqual(AppSettings.hoursToSeconds(0.0), 0, "0 hours = 0 seconds")
        XCTAssertEqual(AppSettings.hoursToSeconds(4.0), 14400, "4 hours = 14400 seconds")
    }

    // MARK: - Edge Cases

    func testEmptyTrackedApps() {
        // Given: An empty tracked apps list saved to UserDefaults
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        testDefaults.set([String](), forKey: "trackedApps")

        // When: Creating a new settings instance
        let newSettings = AppSettings(userDefaults: testDefaults)

        // Then: Should use default apps (not empty array)
        XCTAssertEqual(newSettings.trackedApps.count, 3)
        XCTAssertTrue(newSettings.trackedApps.contains("Cursor"))
        XCTAssertTrue(newSettings.trackedApps.contains("Antigravity"))
        XCTAssertTrue(newSettings.trackedApps.contains("Terminal"))
    }

    func testZeroIdleThreshold() {
        // Given: A zero idle threshold saved to UserDefaults
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        testDefaults.set(0, forKey: "idleThresholdSeconds")

        // When: Creating a new settings instance
        let newSettings = AppSettings(userDefaults: testDefaults)

        // Then: Should use default threshold (180 seconds)
        XCTAssertEqual(newSettings.idleThresholdSeconds, 180)
    }

    func testMultipleSettingsInstances() {
        // Given: Two settings instances using the same UserDefaults suite
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        let settings1 = AppSettings(userDefaults: testDefaults)

        // When: Modifying settings1 and saving
        settings1.setLimit(for: 2, seconds: 5400) // Monday: 1.5 hours
        settings1.idleThresholdSeconds = 240
        settings1.save()

        // Then: A new instance should see the same changes
        let settings2 = AppSettings(userDefaults: testDefaults)
        XCTAssertEqual(settings2.getLimit(for: 2), 5400)
        XCTAssertEqual(settings2.idleThresholdSeconds, 240)
    }
}
