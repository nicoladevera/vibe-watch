//
//  AppDelegate.swift
//  VibeWatch
//
//  AppDelegate for NSStatusBar menu bar integration.
//

import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var iconManager: MenuBarIconManager?

    // Core services
    var settings: AppSettings!
    var timeTracker: TimeTracker!

    // Menu items that need to be updated
    private var todayMenuItem: NSMenuItem?
    private var limitMenuItem: NSMenuItem?
    private var remainingMenuItem: NSMenuItem?

    // Keep strong references to windows
    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?

    // Observers
    private var cancellables = Set<AnyCancellable>()
    private var iconUpdateTimer: Timer?
    private var menuUpdateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🦉 VibeWatch: Application launching...")

        // TEST: Adding AppSettings and TimeTracker
        settings = AppSettings()
        print("✅ Settings initialized")

        timeTracker = TimeTracker(settings: settings)
        print("✅ TimeTracker initialized (NOT started)")

        setupSettingsObservers()

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("✅ Status item created")

        // Set up the button with icon
        if let button = statusItem.button {
            // Load icon from bundle
            var icon: NSImage?
            if let imageURL = Bundle.module.url(forResource: "alert", withExtension: "png") {
                icon = NSImage(contentsOf: imageURL)
                icon?.isTemplate = true
                icon?.size = NSSize(width: 18, height: 18)
                button.image = icon
                print("✅ Button configured with alert icon from bundle")
            } else {
                // Fallback to SF Symbol
                icon = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Vibe Watch")
                icon?.isTemplate = true
                button.image = icon
                print("⚠️ Could not load alert icon, using fallback")
            }
        }

        // Create the menu
        menu = NSMenu()
        setupMenu()
        statusItem.menu = menu
        print("✅ Menu created and configured")

        // TEST: Re-enable icon manager only
        iconManager = MenuBarIconManager(statusItem: statusItem)
        print("✅ Icon manager initialized")

        // Start tracking
        timeTracker.startTracking()
        print("✅ Time tracking started")

        // Set up icon updates every 30 seconds
        iconUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarIcon()
        }

        // Set up menu updates every 10 seconds
        menuUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateMenuItems()
        }

        // Set up sleep/wake notifications
        setupSleepWakeNotifications()

        // Hide the app from the Dock (menu bar only)
        NSApp.setActivationPolicy(.accessory)

        print("🎉 VibeWatch: Setup complete! Icon should be visible in menu bar.")
    }
    
    private func setupSleepWakeNotifications() {
        // Subscribe to sleep and wake notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    private func setupSettingsObservers() {
        settings.$idleThresholdSeconds
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.timeTracker.updateIdleThreshold(seconds: newValue)
            }
            .store(in: &cancellables)

        settings.$showTimeInMenuBar
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)

        settings.$launchAtLogin
            .removeDuplicates()
            .dropFirst()
            .sink { enabled in
                LoginItemManager.setLaunchAtLogin(enabled: enabled)
            }
            .store(in: &cancellables)

        settings.$trackedApps
            .removeDuplicates()
            .sink { [weak self] apps in
                self?.timeTracker.updateTrackedApps(apps)
            }
            .store(in: &cancellables)

        timeTracker.$todayRecord
            .sink { [weak self] _ in
                self?.updateMenuItems()
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
    }
    
    @objc private func systemWillSleep() {
        // Pause tracking and save data before sleep
        timeTracker.stopTracking()
    }

    @objc private func systemDidWake() {
        // Resume tracking after wake
        timeTracker.startTracking()
        updateMenuBarIcon()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Stop tracking and save data
        timeTracker.stopTracking()
    }
    
    private func setupMinimalMenu() {
        // Absolutely minimal test menu
        let item1 = NSMenuItem(title: "🦉 Vibe Watch Test", action: nil, keyEquivalent: "")
        item1.isEnabled = false
        menu.addItem(item1)

        menu.addItem(NSMenuItem.separator())

        let item2 = NSMenuItem(title: "Test Item 1", action: nil, keyEquivalent: "")
        item2.isEnabled = false
        menu.addItem(item2)

        let item3 = NSMenuItem(title: "Test Item 2", action: nil, keyEquivalent: "")
        item3.isEnabled = false
        menu.addItem(item3)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func setupMenu() {
        // Header
        let headerItem = NSMenuItem()
        headerItem.title = "🦉 Vibe Watch"
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Today's time (will be updated)
        todayMenuItem = NSMenuItem()
        todayMenuItem?.title = "Today: 0h 0m"
        todayMenuItem?.isEnabled = false
        menu.addItem(todayMenuItem!)

        // Limit
        limitMenuItem = NSMenuItem()
        limitMenuItem?.title = "Limit: 0h 0m"
        limitMenuItem?.isEnabled = false
        menu.addItem(limitMenuItem!)

        // Remaining
        remainingMenuItem = NSMenuItem()
        remainingMenuItem?.title = "Remaining: 0h 0m"
        remainingMenuItem?.isEnabled = false
        menu.addItem(remainingMenuItem!)

        menu.addItem(NSMenuItem.separator())

        // View History
        let historyItem = NSMenuItem(title: "📊 View History", action: #selector(openHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)

        // Settings
        let settingsItem = NSMenuItem(title: "⚙️  Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Vibe Watch", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // Initial update
        updateMenuItems()
    }

    private func updateMenuItems() {
        // Update today's time
        todayMenuItem?.title = "Today: \(timeTracker.todayRecord.formattedTotalTime())"

        // Update limit
        let limitSeconds = settings.getTodayLimit()
        limitMenuItem?.title = "Limit: \(formatSeconds(limitSeconds))"

        // Update remaining
        let remaining = timeTracker.getTimeRemaining()
        let isOverLimit = timeTracker.isOverLimit()
        if isOverLimit {
            remainingMenuItem?.title = "⚠️ Over limit by \(formatSeconds(-remaining))"
        } else {
            remainingMenuItem?.title = "Remaining: \(formatSeconds(remaining))"
        }
    }

    @objc private func openHistory() {
        // If window already exists, just bring it to front
        if let window = historyWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // Temporarily become regular app to show window
        NSApp.setActivationPolicy(.regular)

        let historyView = HistoryWindowView(timeTracker: timeTracker) { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.historyWindow?.performClose(nil)
            }
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Vibe Watch - History"
        window.contentViewController = NSHostingController(rootView: historyView)
        window.center()
        window.isReleasedWhenClosed = false

        // Store reference before showing
        historyWindow = window

        window.makeKeyAndOrderFront(nil)

        // Activate app in next runloop to avoid blocking
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }

        // Go back to accessory when window closes
        window.delegate = self
    }

    @objc private func openSettings() {
        // If window already exists, just bring it to front
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // Temporarily become regular app to show window
        NSApp.setActivationPolicy(.regular)

        let settingsView = SettingsWindowView(settings: settings) { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.updateMenuItems()
                self?.updateMenuBarIcon()
                self?.settingsWindow?.performClose(nil)
            }
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Vibe Watch - Settings"
        window.contentViewController = NSHostingController(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false

        // Store reference before showing
        settingsWindow = window

        window.makeKeyAndOrderFront(nil)

        // Activate app in next runloop to avoid blocking
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }

        // Go back to accessory when window closes
        window.delegate = self
    }

    private func updateMenuBarIcon() {
        let state = timeTracker.getIconState()
        let timeString = settings.showTimeInMenuBar ? timeTracker.todayRecord.formattedTotalTime() : nil
        iconManager?.updateWithTime(timeString, state: state, animated: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let closedWindow = notification.object as? NSWindow {
            if closedWindow == settingsWindow {
                settingsWindow = nil
            } else if closedWindow == historyWindow {
                historyWindow = nil
            }
        }

        let hasOpenWindows = (settingsWindow != nil) || (historyWindow != nil)
        if !hasOpenWindows {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
