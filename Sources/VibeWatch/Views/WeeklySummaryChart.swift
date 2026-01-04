//
//  WeeklySummaryChart.swift
//  VibeWatch
//
//  Mini bar chart showing last 7 days of coding activity.
//

import SwiftUI

struct WeeklySummaryChart: View {
    var records: [DailyRecord] = []
    
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<7) { index in
                VStack(spacing: 4) {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: dataForDay(index)))
                        .frame(width: 30, height: barHeight(for: dataForDay(index)))
                    
                    // Day label
                    Text(dayLabel(for: index))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 100)
    }
    
    private func dataForDay(_ daysAgo: Int) -> Double {
        // Get data from records for this day
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: Date()) ?? Date()
        let startOfTarget = calendar.startOfDay(for: targetDate)
        
        // Find matching record
        if let record = records.first(where: { calendar.isDate($0.date, inSameDayAs: startOfTarget) }) {
            return Double(record.totalSeconds) / 3600.0 // Convert to hours
        }
        
        return 0
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -(6 - index), to: Date()) ?? Date()
        let weekday = calendar.component(.weekday, from: targetDate)
        return ["S", "M", "T", "W", "T", "F", "S"][weekday - 1]
    }
    
    private func barHeight(for hours: Double) -> CGFloat {
        let maxHeight: CGFloat = 70
        let maxHours: Double = 8.0
        return max(5, CGFloat(hours / maxHours) * maxHeight) // Minimum 5px for visibility
    }
    
    private func barColor(for hours: Double) -> Color {
        if hours > 4.0 {
            return .orange
        } else if hours > 2.0 {
            return .green
        } else if hours > 0 {
            return .blue
        } else {
            return Color.secondary.opacity(0.3)
        }
    }
}

#Preview {
    WeeklySummaryChart()
        .padding()
        .frame(width: 300)
}

