//
//  HistoryView.swift
//  VibeWatch
//
//  Full history view with calendar and charts.
//

import SwiftUI

struct HistoryWindowView: View {
    @ObservedObject var timeTracker: TimeTracker
    var onClose: () -> Void
    @State private var recentRecords: [DailyRecord] = []
    @State private var weeklyRecords: [DailyRecord] = []
    @State private var showExportSheet = false
    @State private var showClearAlert = false
    @State private var weeklyHoverDetail: (date: Date, hours: Double)? = nil
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Coding History")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    weeklySummaryView

                    Divider()
                    
                    // Recent days list
                    recentDaysView
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Export Data") {
                    showExportSheet = true
                }
                
                Spacer()
                
                Button("Clear All Data") {
                    showClearAlert = true
                }
                .foregroundColor(.red)
            }
            .padding()
        }
        .frame(width: 440, height: 520)
        .onAppear {
            loadRecentRecords()
        }
        .onReceive(timeTracker.$isDatabaseReady) { isReady in
            if isReady {
                loadRecentRecords()
            }
        }
        .onReceive(timeTracker.$todayRecord) { _ in
            refreshTodayRecord()
        }
        .alert("Clear All Data?", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all historical data. This action cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportDataView(timeTracker: timeTracker)
        }
    }
    
    private func loadRecentRecords() {
        let recent = timeTracker.getRecentRecords(days: 30)
        recentRecords = mergeTodayRecord(into: recent)

        let weekly = timeTracker.getRecentRecords(days: 7)
        weeklyRecords = mergeTodayRecord(into: weekly)
    }

    private func refreshTodayRecord() {
        recentRecords = mergeTodayRecord(into: recentRecords)
        weeklyRecords = mergeTodayRecord(into: weeklyRecords)
    }

    private func mergeTodayRecord(into records: [DailyRecord]) -> [DailyRecord] {
        var updated = records
        let today = timeTracker.todayRecord
        if let index = updated.firstIndex(where: { $0.isToday() }) {
            updated[index] = today
        } else {
            updated.insert(today, at: 0)
        }
        return updated.sorted { $0.date > $1.date }
    }
    
    private func clearAllData() {
        do {
            try timeTracker.clearAllData()
            recentRecords = []
        } catch {
            print("Error clearing data: \(error)")
        }
    }

    private var weeklySummaryView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This Week")
                .font(.headline)

            WeeklySummaryChart(records: weeklyRecords) { detail in
                weeklyHoverDetail = detail
            }
                .frame(maxWidth: .infinity)

            Text(weeklyDetailText())
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func weeklyDetailText() -> String {
        guard let detail = weeklyHoverDetail else {
            return "Bars show total coding time per day. Hover a day for details."
        }

        return "\(formatDate(detail.date)) • \(formatHours(detail.hours))"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatHours(_ hours: Double) -> String {
        if hours <= 0 {
            return "No activity"
        }

        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        return wholeHours > 0 ? "\(wholeHours)h \(minutes)m" : "\(minutes)m"
    }
    
    private var recentDaysView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity (\(recentRecords.count) days)")
                .font(.headline)
            
            if recentRecords.isEmpty {
                Text("No historical data yet. Start coding to see your activity!")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding()
            } else {
                ForEach(recentRecords) { record in
                    DayRecordRow(record: record)
                }
            }
        }
    }
}

struct DayRecordRow: View {
    let record: DailyRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(record.formattedDate())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(record.formattedTotalTime())
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // App breakdown
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(Array(record.appBreakdown.keys.sorted()), id: \.self) { app in
                    if let seconds = record.appBreakdown[app] {
                        HStack {
                            Text(app)
                                .font(.caption)
                            Text(formatSeconds(seconds))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

struct ExportDataView: View {
    @ObservedObject var timeTracker: TimeTracker
    @Environment(\.dismiss) var dismiss
    @State private var exportFormat: ExportFormat = .csv
    @State private var showSavePanel = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Picker("Format", selection: $exportFormat) {
                Text("CSV").tag(ExportFormat.csv)
                Text("JSON").tag(ExportFormat.json)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Export") {
                    exportData()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
    
    private func exportData() {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "vibe-watch-data.\(exportFormat == .csv ? "csv" : "json")"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let data = try timeTracker.exportData(format: exportFormat)
                    
                    if exportFormat == .json, let jsonData = data as? Data {
                        try jsonData.write(to: url)
                    } else if exportFormat == .csv, let csvString = data as? String {
                        try csvString.write(to: url, atomically: true, encoding: .utf8)
                    }
                    
                    dismiss()
                } catch {
                    print("Export error: \(error)")
                }
            }
        }
    }
}
