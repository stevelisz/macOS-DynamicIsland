import Cocoa
import SwiftUI

class MouseEventMonitor: ObservableObject {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    @Published var isMouseInNotchArea = false
    
    // Notch area dimensions (adjust based on your MacBook model)
    private let notchWidth: CGFloat = 200
    private let notchHeight: CGFloat = 32
    
    func startMonitoring() {
        // Request accessibility permissions first
        requestAccessibilityPermissions()
        
        // Monitor global mouse events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleMouseEvent(event)
            }
        }
        
        // Monitor local mouse events
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleMouseEvent(event)
            }
            return event
        }
    }
    
    func stopMonitoring() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = screen.frame
        
        // Calculate notch area (centered at top of screen)
        let notchRect = NSRect(
            x: (screenFrame.width - notchWidth) / 2,
            y: screenFrame.height - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
        
        let wasInNotchArea = isMouseInNotchArea
        isMouseInNotchArea = notchRect.contains(mouseLocation)
        
        // Handle clicks in notch area
        if (event.type == .leftMouseDown || event.type == .rightMouseDown) && isMouseInNotchArea {
            NotificationCenter.default.post(name: .notchClicked, object: nil)
        }
        
        // Handle mouse enter/exit events
        if wasInNotchArea != isMouseInNotchArea {
            NotificationCenter.default.post(
                name: .mouseNotchStateChanged,
                object: isMouseInNotchArea
            )
        }
    }
    
    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true
        ]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.requestAccessibilityPermissions()
            }
        }
    }
}

// Notification extensions
extension Notification.Name {
    static let notchClicked = Notification.Name("notchClicked")
    static let mouseNotchStateChanged = Notification.Name("mouseNotchStateChanged")
    static let closeDynamicIsland = Notification.Name("closeDynamicIsland")
}
