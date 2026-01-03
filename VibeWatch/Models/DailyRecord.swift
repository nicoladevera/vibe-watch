//
//  DailyRecord.swift
//  VibeWatch
//
//  Data model for daily aggregated time tracking records.
//

import Foundation

struct DailyRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    var totalSeconds: Int
    var appBreakdown: [String: Int] // App name -> seconds
    var hourlyActivity: [Int] // 24 elements, each representing minutes active in that hour
    
    init(id: UUID = UUID(), date: Date) {
        self.id = id
        self.date = date
        self.totalSeconds = 0
        self.appBreakdown = [:]
        self.hourlyActivity = Array(repeating: 0, count: 24)
    }
    
    /// Add time for a specific app
    mutating func addTime(appName: String, seconds: Int, hour: Int) {
        totalSeconds += seconds
        appBreakdown[appName, default: 0] += seconds
        
        if hour >= 0 && hour < 24 {
            hourlyActivity[hour] += seconds / 60 // Convert to minutes
        }
    }
    
    /// Get formatted total time (e.g., "3h 42m")
    func formattedTotalTime() -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Get date string (e.g., "Jan 3, 2026")
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Check if this record is for today
    func isToday() -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

