//
//  MenuBarIcon.swift
//  VibeWatch
//
//  Manages the menu bar icon state and appearance.
//

import Cocoa
import SwiftUI

class MenuBarIconManager {
    private var statusItem: NSStatusItem
    private var currentState: IconState = .alert
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        updateIcon(to: .alert)
    }
    
    /// Update the icon to reflect the current state
    func updateIcon(to state: IconState, animated: Bool = true) {
        guard currentState != state else { return }
        
        currentState = state
        
        if animated {
            // Animate transition with 0.3 second fade
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                statusItem.button?.animator().alphaValue = 0.0
            }, completionHandler: {
                self.setIconImage(for: state)
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    self.statusItem.button?.animator().alphaValue = 1.0
                })
            })
        } else {
            setIconImage(for: state)
        }
    }
    
    /// Set the actual icon image
    private func setIconImage(for state: IconState) {
        let image: NSImage?
        
        switch state {
        case .alert:
            // Happy owl - use moon.stars for now (will replace with custom owl)
            image = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: "Alert")
        case .concerned:
            // Concerned owl - use exclamationmark for now
            image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning")
        case .exhausted:
            // Exhausted owl - use zzz for now
            image = NSImage(systemSymbolName: "powersleep", accessibilityDescription: "Exhausted")
        }
        
        // Configure the image
        image?.isTemplate = true // This makes it adapt to light/dark menu bar
        statusItem.button?.image = image
    }
    
    /// Update icon with optional time text
    func updateWithTime(_ timeString: String?, state: IconState, animated: Bool = true) {
        updateIcon(to: state, animated: animated)

        let title = timeString ?? ""
        statusItem.length = title.isEmpty ? NSStatusItem.squareLength : NSStatusItem.variableLength
        if let button = statusItem.button {
            button.title = title
            button.imagePosition = title.isEmpty ? .imageOnly : .imageLeading
        }
    }
}

// Helper extension for creating custom owl icons from image files
extension MenuBarIconManager {
    /// Load custom owl icon from Resources
    static func loadOwlIcon(named name: String) -> NSImage? {
        // Look for image in Resources folder
        if let image = NSImage(named: name) {
            image.size = NSSize(width: 18, height: 18) // Menu bar icon size
            return image
        }
        return nil
    }
    
    /// Create owl icons from files
    static func setupCustomOwlIcons() {
        // This will be called when we have actual owl icon files
        // For now, we're using SF Symbols as placeholders
    }
}
