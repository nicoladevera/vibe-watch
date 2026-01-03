//
//  TimeEntry.swift
//  VibeWatch
//
//  Data model for individual time tracking entries.
//

import Foundation

struct TimeEntry: Codable {
    let id: UUID
    let date: Date
    let appName: String
    let durationSeconds: Int
    let hourOfDay: Int // 0-23, for hourly activity tracking
    
    init(id: UUID = UUID(), date: Date = Date(), appName: String, durationSeconds: Int) {
        self.id = id
        self.date = date
        self.appName = appName
        self.durationSeconds = durationSeconds
        
        let calendar = Calendar.current
        self.hourOfDay = calendar.component(.hour, from: date)
    }
}

