//
//  VibeWatchApp.swift
//  VibeWatch
//
//  Main app entry point for the Vibe Watch menu bar application.
//

import SwiftUI

@main
struct VibeWatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

