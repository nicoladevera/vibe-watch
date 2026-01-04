//
//  TimeTracker.swift
//  VibeWatch
//
//  Core time tracking service that combines app detection and idle monitoring.
//

import Foundation
import Combine

class TimeTracker: ObservableObject {
    @Published var todayRecord: DailyRecord
    @Published var isTracking: Bool = false
    @Published private(set) var isDatabaseReady: Bool = false
    
    private let appDetector: AppDetector
    private var idleMonitor: IdleMonitor
    private let settings: AppSettings
    private var dataStore: DataStore?  // Made optional - lazy init
    private var timer: DispatchSourceTimer?
    private let trackingQueue = DispatchQueue(label: "vibewatch.tracking", qos: .utility)
    private var lastCheckDate: Date?

    // Configurable timing parameters (defaults for production, can override for testing)
    let pollingInterval: TimeInterval
    let saveThreshold: Int  // Seconds of pending time before auto-save
    let dbInitDelay: TimeInterval

    // Track time per app since last save
    private var pendingTime: [String: Int] = [:]

    /// Initialize TimeTracker with optional test configuration
    init(
        settings: AppSettings,
        dataStore: DataStore? = nil,
        pollingInterval: TimeInterval = 15.0,
        saveThreshold: Int = 300,  // 5 minutes
        dbInitDelay: TimeInterval = 2.0
    ) {
        self.settings = settings
        self.pollingInterval = pollingInterval
        self.saveThreshold = saveThreshold
        self.dbInitDelay = dbInitDelay
        self.appDetector = AppDetector(trackedApps: settings.trackedApps)
        self.idleMonitor = IdleMonitor(idleThresholdSeconds: TimeInterval(settings.idleThresholdSeconds))

        // Initialize today's record with empty data (database loads later)
        self.todayRecord = DailyRecord(date: Date())

        // If DataStore provided (testing), use it immediately
        if let providedDataStore = dataStore {
            self.dataStore = providedDataStore
            self.isDatabaseReady = true
            self.loadTodayRecord()
            print("✅ TimeTracker initialized with provided DataStore")
        } else {
            // Initialize database in background AFTER app is ready (production)
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + dbInitDelay) { [weak self] in
                self?.initializeDatabase()
            }
            print("✅ TimeTracker initialized")
        }
    }
    
    private func initializeDatabase() {
        print("🗄️ Initializing database in background...")
        self.dataStore = DataStore()
        loadTodayRecord()
        DispatchQueue.main.async { [weak self] in
            self?.isDatabaseReady = true
        }
        print("✅ Database ready")
    }

    func updateIdleThreshold(seconds: Int) {
        idleMonitor = IdleMonitor(idleThresholdSeconds: TimeInterval(seconds))
    }

    func updateTrackedApps(_ apps: [String]) {
        appDetector.updateTrackedApps(apps)
    }
    
    /// Start tracking
    func startTracking() {
        guard !isTracking else { return }

        isTracking = true
        lastCheckDate = Date()

        let timer = DispatchSource.makeTimerSource(queue: trackingQueue)
        timer.schedule(deadline: .now() + 1.0, repeating: pollingInterval)
        timer.setEventHandler { [weak self] in
            self?.checkAndTrackTime()
        }
        timer.resume()
        self.timer = timer

        // Initial fire is delayed slightly to avoid doing work during app launch.
    }
    
    /// Stop tracking
    func stopTracking() {
        isTracking = false
        timer?.cancel()
        timer = nil
        
        // Save any pending time
        savePendingTime()
    }
    
    /// Check if we should track time and update accordingly
    private func checkAndTrackTime() {
        let now = Date()
        let calendar = Calendar.current
        let previousCheckDate = lastCheckDate
        let shouldRollDay = previousCheckDate.map { !calendar.isDate($0, inSameDayAs: now) } ?? false

        // Check if date has changed (midnight passed)
        if shouldRollDay {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // New day! Save old record and create new one
                self.savePendingTime()
                self.todayRecord = DailyRecord(date: now)
                self.loadTodayRecord()
            }
        }
        lastCheckDate = now
        
        // Check if any tracked app is running (AppKit access on main)
        let runningApps = DispatchQueue.main.sync { appDetector.getRunningAppNames() }
        guard !runningApps.isEmpty else { return }
        
        // Check if user is active
        guard idleMonitor.isUserActive() else { return }
        
        // Track time! Add the polling interval to each running app
        let currentHour = calendar.component(.hour, from: now)
        let elapsedSeconds = Int(pollingInterval)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.todayRecord.addTotalTime(seconds: elapsedSeconds, hour: currentHour)
            for appName in runningApps {
                self.pendingTime[appName, default: 0] += elapsedSeconds
                self.todayRecord.addAppTime(appName: appName, seconds: elapsedSeconds)
            }

            // Check if we should persist (based on save threshold)
            let totalPendingSeconds = self.pendingTime.values.reduce(0, +)
            if totalPendingSeconds >= self.saveThreshold {
                self.savePendingTime()
            }
        }
    }
    
    /// Save pending time to storage
    private func savePendingTime() {
        guard !pendingTime.isEmpty else { return }
        guard let dataStore = dataStore else { return }
        
        // Save to DataStore
        do {
            try dataStore.saveDailyRecord(todayRecord)
        } catch {
            print("Error saving daily record: \(error)")
        }
        
        // Clear pending time
        pendingTime = [:]
    }
    
    /// Load today's record from storage
    private func loadTodayRecord() {
        guard let dataStore = dataStore else { return }
        
        do {
            if let stored = try dataStore.fetchTodayRecord() {
                DispatchQueue.main.async { [weak self] in
                    self?.todayRecord = stored
                }
            }
        } catch {
            print("Error loading today's record: \(error)")
        }
    }
    
    /// Get time remaining before hitting today's limit
    func getTimeRemaining() -> Int {
        let limit = settings.getTodayLimit()
        let remaining = limit - todayRecord.totalSeconds
        return max(0, remaining)
    }
    
    /// Get the current icon state based on time remaining
    func getIconState() -> IconState {
        let remaining = getTimeRemaining()
        let oneHour = 3600
        
        if remaining > oneHour {
            return .alert // Happy/alert owl
        } else if remaining > 0 {
            return .concerned // Warning owl
        } else {
            return .exhausted // Sleepy owl
        }
    }
    
    /// Check if limit has been exceeded
    func isOverLimit() -> Bool {
        return todayRecord.totalSeconds >= settings.getTodayLimit()
    }
    
    /// Get historical records
    func getRecentRecords(days: Int) -> [DailyRecord] {
        guard let dataStore = dataStore else { return [] }
        do {
            return try dataStore.fetchRecentRecords(days: days)
        } catch {
            print("Error fetching recent records: \(error)")
            return []
        }
    }
    
    /// Export data
    func exportData(format: ExportFormat) throws -> Any {
        guard let dataStore = dataStore else { 
            throw NSError(domain: "VibeWatch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"])
        }
        switch format {
        case .json:
            return try dataStore.exportAsJSON()
        case .csv:
            return try dataStore.exportAsCSV()
        }
    }
    
    /// Clear all historical data
    func clearAllData() throws {
        guard let dataStore = dataStore else { return }
        try dataStore.deleteAllRecords()
        todayRecord = DailyRecord(date: Date())
    }
}

enum ExportFormat {
    case json
    case csv
}

// Icon states for the owl
enum IconState {
    case alert      // Wide awake, >1h remaining
    case concerned  // Worried, <1h remaining
    case exhausted  // Sleepy, over limit
}
