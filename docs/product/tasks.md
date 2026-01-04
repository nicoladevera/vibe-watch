# Tasks: Vibe Watch

## Relevant Files

- `VibeWatch/VibeWatchApp.swift` - Main app entry point, menu bar app configuration
- `VibeWatch/AppDelegate.swift` - AppDelegate for NSStatusBar menu bar integration
- `VibeWatch/Models/TimeEntry.swift` - Data model for tracking time entries
- `VibeWatch/Models/DailyRecord.swift` - Data model for daily aggregated records
- `VibeWatch/Models/AppSettings.swift` - User settings and daily limits model
- `VibeWatch/Services/TimeTracker.swift` - Core time tracking logic (app detection, idle monitoring)
- `VibeWatch/Services/TimeTrackerTests.swift` - Unit tests for TimeTracker
- `VibeWatch/Services/AppDetector.swift` - Detects running coding applications
- `VibeWatch/Services/AppDetectorTests.swift` - Unit tests for AppDetector
- `VibeWatch/Services/IdleMonitor.swift` - Monitors system idle time via ioreg
- `VibeWatch/Services/IdleMonitorTests.swift` - Unit tests for IdleMonitor
- `VibeWatch/Services/DataStore.swift` - SQLite/Core Data persistence layer
- `VibeWatch/Services/DataStoreTests.swift` - Unit tests for DataStore
- `VibeWatch/Views/MenuBarIcon.swift` - Menu bar icon view with eye icon states
- `VibeWatch/Views/DropdownPanel.swift` - Main dropdown panel UI
- `VibeWatch/Views/WeeklySummaryChart.swift` - Mini bar chart for weekly summary
- `VibeWatch/Views/SettingsView.swift` - Settings window for configuring limits
- `VibeWatch/Views/HistoryView.swift` - Full history view with calendar and charts
- `VibeWatch/Views/HourlyActivityChart.swift` - 24-hour activity visualization
- `VibeWatch/Resources/` - Eye icons (alert.png, concerned.png, exhausted.png) with transparent backgrounds
- `VibeWatch/Utilities/TimeFormatter.swift` - Helper for formatting time as "Xh Ym"
- `VibeWatch/Utilities/ExportManager.swift` - CSV/JSON export functionality

### Notes

- Unit tests should typically be placed alongside the code files they are testing or in a parallel `VibeWatchTests/` directory.
- Use `swift test` or Xcode's test runner (Cmd+U) to execute tests.
- This is a native macOS menu bar application built with Swift and SwiftUI.
- Menu bar apps require `LSUIElement` set to `YES` in Info.plist to hide from Dock.
- Eye icons use PNG format with transparent backgrounds and are made square to prevent stretching in the menu bar.

## Instructions for Completing Tasks

**IMPORTANT:** As you complete each task, you must check it off in this markdown file by changing `- [ ]` to `- [x]`. This helps track progress and ensures you don't skip any steps.

Example:
- `- [ ] 1.1 Read file` → `- [x] 1.1 Read file` (after completing)

Update the file after completing each sub-task, not just after completing an entire parent task.

## Tasks

- [x] 0.0 Create feature branch
  - [x] 0.1 Initialize a new git repository if not already initialized (`git init`)
  - [x] 0.2 Create and checkout a new branch for this feature (`git checkout -b feature/vibe-watch-v1`)

- [x] 1.0 Set up macOS menu bar application project
  - [x] 1.1 Create a new Xcode project with macOS App template using Swift and SwiftUI
  - [x] 1.2 Configure the app as a menu bar app (set `LSUIElement` to `YES` in Info.plist to hide Dock icon)
  - [x] 1.3 Set up `NSStatusBar` integration in AppDelegate to display menu bar icon
  - [x] 1.4 Create basic project folder structure (`Models/`, `Views/`, `Services/`, `Utilities/`, `Resources/`)
  - [x] 1.5 Add placeholder icon to menu bar to verify setup works
  - [x] 1.6 Configure app to build and run, confirming icon appears in menu bar

- [x] 2.0 Implement core time tracking engine
  - [x] 2.1 Create `AppDetector` service that uses `NSWorkspace.shared.runningApplications` to detect if Cursor, Antigravity, or Terminal are running
  - [x] 2.2 Create `IdleMonitor` service that runs `ioreg -c IOHIDSystem` to get `HIDIdleTime` and converts nanoseconds to seconds
  - [x] 2.3 Create `TimeTracker` service that combines app detection and idle monitoring with 30-second polling interval
  - [x] 2.4 Implement logic: only count time when (tracked app running) AND (idle time < 3 minutes)
  - [x] 2.5 Track time per-app (separate counters for Cursor, Antigravity, Terminal)
  - [x] 2.6 Implement midnight reset logic (detect date change and reset daily counters)
  - [x] 2.7 Write unit tests for `AppDetector` (mock running applications)
  - [x] 2.8 Write unit tests for `IdleMonitor` (mock shell command output)
  - [x] 2.9 Write unit tests for `TimeTracker` (test time accumulation logic)

- [x] 3.0 Build menu bar icon with expressive states
  - [x] 3.1 Source or create three eye icons: Alert (wide eyes), Concerned (worried eyes), Exhausted (tired/sleepy eyes)
  - [x] 3.2 Process icons: remove backgrounds, make square to prevent stretching, export as PNG with transparency
  - [x] 3.3 Add icons to `Resources/` folder with proper naming (`alert.png`, `concerned.png`, `exhausted.png`)
  - [x] 3.4 Create `MenuBarIcon` component that selects icon based on time remaining vs. limit
  - [x] 3.5 Implement icon state logic: Alert (>1h remaining), Concerned (≤1h remaining), Exhausted (over limit)
  - [x] 3.6 Add 0.3-second fade transition between icon states using `NSStatusBarButton` animation
  - [x] 3.7 Optionally display time text next to icon (e.g., "3h") based on user preference

- [x] 4.0 Create dropdown panel UI
  - [x] 4.1 Create `DropdownPanel` SwiftUI view as the popover content when menu bar icon is clicked
  - [x] 4.2 Display today's total vibe coding time prominently (e.g., "Today: 3h 42m")
  - [x] 4.3 Display daily limit and remaining time (e.g., "Limit: 4h · 18m remaining")
  - [x] 4.4 Create `WeeklySummaryChart` component showing last 7 days as horizontal bar chart
  - [x] 4.5 Add "View History" button that opens the full history window
  - [x] 4.6 Add "Settings" button (gear icon) that opens the settings window
  - [x] 4.7 Add "Quit" menu item to exit the application
  - [x] 4.8 Style dropdown to match macOS system UI (use native colors, SF Symbols)

- [x] 5.0 Implement settings and daily limits configuration
  - [x] 5.1 Create `AppSettings` model to store user preferences (limits, idle threshold, launch at startup)
  - [x] 5.2 Implement per-day-of-week limit storage (Monday through Sunday, each with own limit)
  - [x] 5.3 Set default limits: 4 hours for weekdays (Mon-Fri), 2 hours for weekends (Sat-Sun)
  - [x] 5.4 Create `SettingsView` SwiftUI window with limit sliders (15-minute increments, 0-12 hours)
  - [ ] 5.5 Add toggle for "Launch at Login" using `SMAppService` (macOS 13+) or `LSSharedFileList`
  - [x] 5.6 Add configurable idle threshold setting (default 3 minutes)
  - [x] 5.7 Persist settings using `UserDefaults` or `@AppStorage`
  - [x] 5.8 Ensure limit changes take effect immediately for current day

- [x] 6.0 Build historical data storage and visualization
  - [x] 6.1 Create `DailyRecord` model with: date, total time, per-app breakdown, hourly activity array (24 booleans/minutes)
  - [x] 6.2 Set up SQLite database using GRDB.swift or Core Data for persistent storage
  - [x] 6.3 Implement `DataStore` service with methods: saveDailyRecord, fetchRecords(dateRange), deleteAllRecords
  - [x] 6.4 Persist accumulated time to storage every 5 minutes (and on app quit)
  - [x] 6.5 Create `HistoryView` window showing daily totals in list or calendar heat-map format
  - [x] 6.6 Create `HourlyActivityChart` showing 24-hour timeline with colored blocks for active hours
  - [x] 6.7 Display per-app breakdown for selected day (horizontal stacked bar or pie chart)
  - [x] 6.8 Implement `ExportManager` to export data as CSV or JSON file
  - [x] 6.9 Add "Export Data" button in history view with file save dialog
  - [x] 6.10 Add "Clear All Data" button with confirmation alert
  - [x] 6.11 Write unit tests for `DataStore` (test save, fetch, delete operations)

- [x] 7.0 System integration and polish
  - [x] 7.1 Handle system sleep/wake events using `NSWorkspace.willSleepNotification` and `didWakeNotification`
  - [x] 7.2 Pause time tracking during sleep, resume on wake
  - [x] 7.3 Ensure tracking continues across desktop/space switches (no special handling needed, just verify)
  - [x] 7.4 Store data in `~/Library/Application Support/VibeWatch/` directory
  - [ ] 7.5 Add app icon for Settings window and About dialog
  - [x] 7.6 Test complete user flow: launch → track time → view dropdown → change settings → view history → export → quit
  - [ ] 7.7 Profile app for resource usage (target: <1% CPU, <50MB RAM)
  - [ ] 7.8 Fix any remaining bugs or UI polish issues
  - [x] 7.9 Create README.md with build instructions and feature overview
