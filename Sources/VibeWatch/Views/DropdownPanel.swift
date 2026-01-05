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
    var onOpenHistory: () -> Void
    var onOpenSettings: () -> Void
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
            
            // Actions
            actionsView
                .padding(.vertical, 8)
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            iconView
                .frame(width: 18, height: 18)
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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Spacer()
                Text(timeTracker.todayRecord.formattedTotalTime())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(iconColor)
            }
            
            // Limit and remaining
            HStack {
                HStack(spacing: 6) {
                    Text("Limit:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatSeconds(settings.getTodayLimit()))
                        .font(.subheadline)
                }

                Spacer()
                
                HStack(spacing: 6) {
                    if timeTracker.isOverLimit() {
                        Text("Over limit by")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatSeconds(timeTracker.getOverLimitSeconds()))
                            .font(.subheadline)
                            .foregroundColor(.red)
                    } else {
                        Text("Remaining:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatSeconds(timeTracker.getTimeRemaining()))
                            .font(.subheadline)
                    }
                }
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
                onOpenHistory()
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            
            Button("Settings") {
                onOpenSettings()
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

    private var iconView: some View {
        let name = iconName(for: timeTracker.getIconState())
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            image.isTemplate = true
            return AnyView(
                Image(nsImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.white)
            )
        }

        return AnyView(
            Image(systemName: "eye.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(.white)
        )
    }

    private func iconName(for state: IconState) -> String {
        switch state {
        case .alert: return "alert"
        case .concerned: return "concerned"
        case .exhausted: return "exhausted"
        }
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
