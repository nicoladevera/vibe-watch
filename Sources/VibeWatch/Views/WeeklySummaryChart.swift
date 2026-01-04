//
//  WeeklySummaryChart.swift
//  VibeWatch
//
//  Mini bar chart showing last 7 days of coding activity.
//

import SwiftUI

struct WeeklySummaryChart: View {
    var records: [DailyRecord] = []
    var onHover: ((Date, Double)?) -> Void = { _ in }
    @State private var hoveredIndex: Int? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 8
            let barCount: CGFloat = 7
            let barWidth = max(18, (geometry.size.width - spacing * (barCount - 1)) / barCount)

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(0..<7) { index in
                    let hours = dataForDay(index)
                    let date = dateForIndex(index)

                    VStack(spacing: 2) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: hours))
                            .frame(width: barWidth, height: barHeight(for: hours))
                            .onHover { isHovering in
                                if isHovering {
                                    hoveredIndex = index
                                    onHover((date, hours))
                                } else if hoveredIndex == index {
                                    hoveredIndex = nil
                                    onHover(nil)
                                }
                            }

                        // Day label
                        Text(dayLabel(for: date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: barWidth)
                    }
                }
            }
        }
        .frame(height: 64)
    }
    
    private func dateForIndex(_ index: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -(6 - index), to: Date()) ?? Date()
    }

    private func dataForDay(_ daysAgo: Int) -> Double {
        // Get data from records for this day
        let calendar = Calendar.current
        let targetDate = dateForIndex(daysAgo)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        
        // Find matching record
        if let record = records.first(where: { calendar.isDate($0.date, inSameDayAs: startOfTarget) }) {
            return Double(record.totalSeconds) / 3600.0 // Convert to hours
        }
        
        return 0
    }
    
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return ["S", "M", "T", "W", "T", "F", "S"][weekday - 1]
    }
    
    private func barHeight(for hours: Double) -> CGFloat {
        let maxHeight: CGFloat = 40
        let maxHours: Double = 8.0
        return max(5, CGFloat(hours / maxHours) * maxHeight) // Minimum 5px for visibility
    }
    
    private func barColor(for hours: Double) -> Color {
        guard hours > 0 else {
            return Color.secondary.opacity(0.25)
        }

        let intensity = min(1.0, max(0.3, hours / 6.0))
        return Color.accentColor.opacity(intensity)
    }

}

#Preview {
    WeeklySummaryChart()
        .padding()
        .frame(width: 300)
}
