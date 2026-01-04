//
//  DropdownPanel.swift
//  VibeWatch
//
//  Main dropdown panel UI that appears when clicking the menu bar icon.
//

import SwiftUI

struct DropdownPanelView: View {
    @ObservedObject var timeTracker: TimeTracker
    @ObservedObject var settings: AppSettings
    var onQuit: () -> Void
    
    @State private var showHistory = false
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
            
            Divider()
            
            // Today's stats
            todayStatsView
                .padding()
            
            Divider()
            
            // Weekly summary placeholder
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.headline)
                Text("Weekly chart coming soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()
            
            // Actions
            actionsView
                .padding(.vertical, 8)
        }
        .frame(width: 320, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("Vibe Watch")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    private var todayStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Today's total time
            HStack {
                Text("Today:")
                    .font(.headline)
                Spacer()
                Text(timeTracker.todayRecord.formattedTotalTime())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(iconColor)
            }
            
            // Limit and remaining
            HStack {
                Text("Limit:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatSeconds(settings.getTodayLimit()))
                    .font(.subheadline)
                
                Spacer()
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(formatSeconds(timeTracker.getTimeRemaining())) remaining")
                    .font(.subheadline)
                    .foregroundColor(timeTracker.isOverLimit() ? .red : .secondary)
            }
            
            // Progress bar
            ProgressView(value: Double(timeTracker.todayRecord.totalSeconds),
                        total: Double(settings.getTodayLimit()))
                .tint(progressColor)
        }
    }
    private var actionsView: some View {
        VStack(spacing: 6) {
            Button("View History") {
                print("History clicked")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            
            Button("Settings") {
                print("Settings clicked")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            
            Divider()
            
            Button("Quit Vibe Watch") {
                onQuit()
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
    
    // Helper computed properties
    private var iconColor: Color {
        switch timeTracker.getIconState() {
        case .alert: return .green
        case .concerned: return .orange
        case .exhausted: return .red
        }
    }
    
    private var progressColor: Color {
        switch timeTracker.getIconState() {
        case .alert: return .green
        case .concerned: return .orange
        case .exhausted: return .red
        }
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

