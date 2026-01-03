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
    
    private let appDetector: AppDetector
    private let idleMonitor: IdleMonitor
    private let settings: AppSettings
    private var dataStore: DataStore?  // Made optional - lazy init
    private var timer: Timer?
    private var lastCheckDate: Date?
    
    // Polling interval: 30 seconds
    private let pollingInterval: TimeInterval = 30.0
    
    // Track time per app since last save
    private var pendingTime: [String: Int] = [:]
    
    init(settings: AppSettings) {
        self.settings = settings
        self.appDetector = AppDetector()
        self.idleMonitor = IdleMonitor(idleThresholdSeconds: TimeInterval(settings.idleThresholdSeconds))
        
        // Initialize today's record with empty data (database loads later)
        self.todayRecord = DailyRecord(date: Date())
        
        // Initialize database in background AFTER app is ready
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.initializeDatabase()
        }
        
        print("✅ TimeTracker initialized")
    }
    
    private func initializeDatabase() {
        print("🗄️ Initializing database in background...")
        self.dataStore = DataStore()
        loadTodayRecord()
        print("✅ Database ready")
    }
    
    /// Start tracking
    func startTracking() {
        guard !isTracking else { return }

        isTracking = true
        lastCheckDate = Date()

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkAndTrackTime()
        }

        // Don't run immediately - it blocks the main thread during app launch
        // The timer will fire after 30 seconds
        // checkAndTrackTime()
    }
    
    /// Stop tracking
    func stopTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil
        
        // Save any pending time
        savePendingTime()
    }
    
    /// Check if we should track time and update accordingly
    private func checkAndTrackTime() {
        // Check if date has changed (midnight passed)
        if let lastDate = lastCheckDate, !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            // New day! Save old record and create new one
            savePendingTime()
            todayRecord = DailyRecord(date: Date())
            loadTodayRecord()
        }
        lastCheckDate = Date()
        
        // Check if any tracked app is running
        guard appDetector.isAnyTrackedAppRunning() else {
            return
        }
        
        // Check if user is active
        guard idleMonitor.isUserActive() else {
            return
        }
        
        // Track time! Add the polling interval to each running app
        let runningApps = appDetector.getRunningAppNames()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        
        for appName in runningApps {
            pendingTime[appName, default: 0] += Int(pollingInterval)
            todayRecord.addTime(appName: appName, seconds: Int(pollingInterval), hour: currentHour)
        }
        
        // Check if we should persist (every 5 minutes worth of checks)
        let totalPendingSeconds = pendingTime.values.reduce(0, +)
        if totalPendingSeconds >= 300 { // 5 minutes
            savePendingTime()
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

