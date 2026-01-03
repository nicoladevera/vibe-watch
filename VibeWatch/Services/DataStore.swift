//
//  DataStore.swift
//  VibeWatch
//
//  SQLite persistence layer using GRDB for historical records.
//

import Foundation
import GRDB

class DataStore {
    private var dbQueue: DatabaseQueue?
    private let dbPath: String
    
    init() {
        // Create database in Application Support directory
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vibeWatchDir = appSupport.appendingPathComponent("VibeWatch", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: vibeWatchDir, withIntermediateDirectories: true)
        
        dbPath = vibeWatchDir.appendingPathComponent("vibewatch.sqlite").path
        
        do {
            dbQueue = try DatabaseQueue(path: dbPath)
            try setupDatabase()
        } catch {
            print("Failed to initialize database: \(error)")
        }
    }
    
    /// Set up database schema
    private func setupDatabase() throws {
        try dbQueue?.write { db in
            // Create daily_records table
            try db.create(table: "daily_records", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("date", .date).notNull().unique()
                table.column("total_seconds", .integer).notNull()
                table.column("app_breakdown", .text).notNull() // JSON
                table.column("hourly_activity", .text).notNull() // JSON array of 24 integers
            }
            
            // Create index on date for faster queries
            try db.create(index: "idx_date", on: "daily_records", columns: ["date"], ifNotExists: true)
        }
    }
    
    /// Save or update a daily record
    func saveDailyRecord(_ record: DailyRecord) throws {
        try dbQueue?.write { db in
            // Convert app breakdown and hourly activity to JSON
            let appBreakdownJSON = try JSONEncoder().encode(record.appBreakdown)
            let hourlyActivityJSON = try JSONEncoder().encode(record.hourlyActivity)
            
            let appBreakdownString = String(data: appBreakdownJSON, encoding: .utf8) ?? "{}"
            let hourlyActivityString = String(data: hourlyActivityJSON, encoding: .utf8) ?? "[]"
            
            // Normalize date to start of day
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: record.date)
            
            // Insert or replace
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO daily_records 
                    (id, date, total_seconds, app_breakdown, hourly_activity)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                arguments: [
                    record.id.uuidString,
                    startOfDay,
                    record.totalSeconds,
                    appBreakdownString,
                    hourlyActivityString
                ]
            )
        }
    }
    
    /// Fetch records for a date range
    func fetchRecords(from startDate: Date, to endDate: Date) throws -> [DailyRecord] {
        guard let dbQueue = dbQueue else { return [] }
        
        return try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                    SELECT * FROM daily_records 
                    WHERE date >= ? AND date <= ?
                    ORDER BY date DESC
                    """,
                arguments: [startDate, endDate]
            )
            
            return try rows.map { row in
                try parseDailyRecord(from: row)
            }
        }
    }
    
    /// Fetch today's record
    func fetchTodayRecord() throws -> DailyRecord? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        guard let dbQueue = dbQueue else { return nil }
        
        return try dbQueue.read { db in
            if let row = try Row.fetchOne(
                db,
                sql: "SELECT * FROM daily_records WHERE date = ?",
                arguments: [startOfDay]
            ) {
                return try parseDailyRecord(from: row)
            }
            return nil
        }
    }
    
    /// Fetch last N days of records
    func fetchRecentRecords(days: Int) throws -> [DailyRecord] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        return try fetchRecords(from: startDate, to: endDate)
    }
    
    /// Delete all records (with confirmation from caller)
    func deleteAllRecords() throws {
        try dbQueue?.write { db in
            try db.execute(sql: "DELETE FROM daily_records")
        }
    }
    
    /// Export all records as JSON
    func exportAsJSON() throws -> Data {
        let allRecords = try fetchRecords(
            from: Date.distantPast,
            to: Date()
        )
        return try JSONEncoder().encode(allRecords)
    }
    
    /// Export all records as CSV
    func exportAsCSV() throws -> String {
        let allRecords = try fetchRecords(
            from: Date.distantPast,
            to: Date()
        )
        
        var csv = "Date,Total Hours,Total Minutes"
        
        // Add app column headers
        let allApps = Set(allRecords.flatMap { $0.appBreakdown.keys })
        for app in allApps.sorted() {
            csv += ",\(app) (minutes)"
        }
        csv += "\n"
        
        // Add data rows
        for record in allRecords {
            let hours = record.totalSeconds / 3600
            let minutes = (record.totalSeconds % 3600) / 60
            csv += "\(record.formattedDate()),\(hours),\(minutes)"
            
            for app in allApps.sorted() {
                let appMinutes = (record.appBreakdown[app] ?? 0) / 60
                csv += ",\(appMinutes)"
            }
            csv += "\n"
        }
        
        return csv
    }
    
    /// Parse a DailyRecord from a database row
    private func parseDailyRecord(from row: Row) throws -> DailyRecord {
        let id = UUID(uuidString: row["id"]) ?? UUID()
        let date: Date = row["date"]
        let totalSeconds: Int = row["total_seconds"]
        
        // Parse JSON strings
        let appBreakdownString: String = row["app_breakdown"]
        let hourlyActivityString: String = row["hourly_activity"]
        
        let appBreakdown = try JSONDecoder().decode(
            [String: Int].self,
            from: appBreakdownString.data(using: .utf8) ?? Data()
        )
        
        let hourlyActivity = try JSONDecoder().decode(
            [Int].self,
            from: hourlyActivityString.data(using: .utf8) ?? Data()
        )
        
        var record = DailyRecord(id: id, date: date)
        record.totalSeconds = totalSeconds
        record.appBreakdown = appBreakdown
        record.hourlyActivity = hourlyActivity
        
        return record
    }
}

