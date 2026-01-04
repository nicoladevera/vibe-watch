//
//  LoginItemManager.swift
//  VibeWatch
//
//  Manage launch-at-login using ServiceManagement.
//

import Foundation
import ServiceManagement

enum LoginItemManager {
    static func setLaunchAtLogin(enabled: Bool) {
        guard #available(macOS 13.0, *) else {
            print("Launch at login requires macOS 13 or later.")
            return
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login update failed: \(error)")
        }
    }
}
