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
        let imageName: String

        switch state {
        case .alert:
            // Alert eyes - wide awake and energetic
            imageName = "alert"
        case .concerned:
            // Concerned eyes - worried
            imageName = "concerned"
        case .exhausted:
            // Exhausted eyes - sleepy/tired
            imageName = "exhausted"
        }

        // Load image from module bundle
        let image = loadImageFromBundle(named: imageName)

        // Configure the image
        if let img = image {
            img.isTemplate = true // This makes it adapt to light/dark menu bar
            img.size = NSSize(width: 18, height: 18) // Menu bar icon size
        }
        statusItem.button?.image = image
    }

    /// Load image from the module's resource bundle
    private func loadImageFromBundle(named name: String) -> NSImage? {
        // Try loading from Bundle.module (SPM resources)
        if let imageURL = Bundle.module.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: imageURL) {
            print("✅ Loaded \(name).png from bundle")
            return image
        }

        print("⚠️ Could not load \(name).png from bundle, trying NSImage(named:)")
        // Fallback to named image
        return NSImage(named: name)
    }
    
    /// Update icon with optional time text
    func updateWithTime(_ timeString: String?, state: IconState, animated: Bool = true) {
        updateIcon(to: state, animated: animated)

        if let button = statusItem.button {
            if let timeString = timeString, !timeString.isEmpty {
                // Show both icon and time
                button.title = " \(timeString)" // Space for padding between icon and text
                button.imagePosition = .imageLeading
                statusItem.length = NSStatusItem.variableLength
            } else {
                // Show only icon
                button.title = ""
                button.imagePosition = .imageOnly
                statusItem.length = NSStatusItem.squareLength
            }
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
