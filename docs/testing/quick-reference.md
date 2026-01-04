# Testing Quick Reference

**Quick action guide for implementing testing improvements**

## Current Status (2026-01-04)
- Test Coverage: ~32-35% (up from ~8%)
- Tests Passing: 59/59 (up from 12/12)
- CI/CD: None
- Risk Level: Medium (reduced from Medium-High)

---

## Critical Gaps (Fix First)

### 1. DataStore ✅ COMPLETED
**File**: `Sources/VibeWatch/Services/DataStore.swift`
**Status**: 13 tests added covering CRUD operations, exports, and edge cases

Tests implemented:
- ✅ saveRecord() / getRecord()
- ✅ exportToCSV() / exportToJSON()
- ✅ getRecords() / getWeekRecords()

### 2. AppSettings ✅ COMPLETED
**File**: `Sources/VibeWatch/Models/AppSettings.swift`
**Status**: 18 tests added covering defaults, persistence, functionality, and edge cases

Tests implemented:
- ✅ Daily limit persistence (all 7 days)
- ✅ Tracked apps persistence
- ✅ Default values
- ✅ Settings isolation with test UserDefaults

### 3. TimeTracker Complex Logic ✅ COMPLETED
**File**: `Sources/VibeWatch/Services/TimeTracker.swift`
**Status**: Extended from 5 to 21 tests with integration tests

Tests implemented:
- ✅ Day rollover handling
- ✅ Pending time accumulation
- ✅ Save threshold logic
- ✅ DataStore integration
- ✅ Icon state transitions

---

## Implementation Checklist

### Phase 1: Core Tests ✅ COMPLETED (4-6 hours)
- [x] Create DataStoreTests.swift with temp database (13 tests)
- [x] Create AppSettingsTests.swift with test UserDefaults (18 tests)
- [x] Extend TimeTrackerTests.swift with integration tests (16 new tests)
- [x] Fix test warnings (IdleMonitorTests:37, AppDetectorTests:41)
- [x] Run `swift test` - all 59 tests passing (0.246s)

### Phase 2: CI/CD (1-2 hours)
- [ ] Create `.github/workflows/ci.yml`
- [ ] Add test job (runs on push/PR)
- [ ] Add build job (release configuration)
- [ ] Optional: Add SwiftLint
- [ ] Push and verify workflow runs

### Phase 3: Improvements (2-3 hours)
- [ ] Create TestHelpers.swift with fixtures
- [ ] Add edge case tests
- [ ] Make tests environment-independent
- [ ] Remove test flakiness

---

## Quick Commands

```bash
# Run all tests
swift test

# Run specific test
swift test --filter TimeTrackerTests

# Build project
swift build

# Build release
swift build --configuration release

# Check test coverage (requires Xcode)
swift test --enable-code-coverage
```

---

## Sample Test Structure

### DataStore Test
```swift
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
        super.tearDown()
    }

    func testSaveAndLoadRecord() throws {
        // Given
        var record = DailyRecord(date: Date())
        record.addTime(300, for: "Cursor")

        // When
        try dataStore.saveRecord(record)
        let loaded = try dataStore.getRecord(for: Date())

        // Then
        XCTAssertEqual(loaded.totalSeconds, 300)
    }
}
```

### Basic CI Workflow
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-13
    steps:
    - uses: actions/checkout@v4
    - uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    - run: swift build
    - run: swift test
```

---

## Files to Create

### Tests
1. `Tests/VibeWatchTests/DataStoreTests.swift`
2. `Tests/VibeWatchTests/AppSettingsTests.swift`
3. `Tests/VibeWatchTests/TestHelpers.swift` (optional)

### CI/CD
1. `.github/workflows/ci.yml`
2. `.swiftlint.yml` (optional)

---

## Success Criteria

### Minimum (Phase 1 + 2)
- ✅ DataStore has >70% coverage (ACHIEVED)
- ✅ AppSettings has >70% coverage (ACHIEVED)
- ✅ TimeTracker has >70% coverage (ACHIEVED)
- [ ] CI runs on all PRs (Phase 2 pending)
- ✅ All tests pass (59/59 passing)
- ✅ Zero test warnings (ACHIEVED)

### Ideal (All Phases)
- [ ] Project has >80% coverage (currently ~32-35%)
- ✅ Zero flaky tests (ACHIEVED)
- [ ] Test helpers in place (Phase 3 pending)
- [ ] SwiftLint passing (Phase 2 optional)

---

## Key Principles

1. **Isolation**: Use temp databases, test UserDefaults
2. **Fast**: Keep tests under 0.1s each
3. **Deterministic**: No environment dependencies
4. **Clear**: Use Given-When-Then structure

---

See `testing-recommendations.md` for full details.
