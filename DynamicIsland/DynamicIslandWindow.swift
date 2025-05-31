import SwiftUI
import Cocoa
import Foundation

class DynamicIslandWindow: NSPanel {
    private var trackingArea: NSTrackingArea?
    var isDetached: Bool = false
    private let notchThreshold: CGFloat = 30 // Increased from 10px to 30px for less sensitivity
    private let headerHeight: CGFloat = 140 // Updated to match SwiftUI header
    private var positionMonitorTimer: Timer?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 450),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        startPositionMonitoring()
    }
    
    private func setupWindow() {
        // Window appearance
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        
        // Window behavior
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isMovable = true // Enable native dragging
        self.isMovableByWindowBackground = false // Disable general dragging - we'll add specific drag areas
        self.acceptsMouseMovedEvents = true
        
        // Positioning
        self.hidesOnDeactivate = false
        self.animationBehavior = .none
        
        // Make sure it appears above everything
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)) + 1)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        positionMonitorTimer?.invalidate()
    }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        addTrackingAreaIfNeeded()
    }
    
    private func addTrackingAreaIfNeeded() {
        if let trackingArea = trackingArea {
            self.contentView?.removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: self.contentView?.bounds ?? .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        self.contentView?.addTrackingArea(area)
        self.trackingArea = area
    }
    
    override func mouseEntered(with event: NSEvent) {
        NotificationCenter.default.post(name: .dynamicIslandMouseEntered, object: nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        NotificationCenter.default.post(name: .dynamicIslandMouseExited, object: nil)
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    // Custom positioning method
    func positionNearNotch() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowSize = self.frame.size
        
        let newOrigin = CGPoint(
            x: (screenFrame.width - windowSize.width) / 2,
            y: screenFrame.height - windowSize.height - 40 // 40px below top edge
        )
        
        self.setFrameOrigin(newOrigin)
    }
    
    override func setFrameOrigin(_ point: NSPoint) {
        super.setFrameOrigin(point)
        checkDetachment()
    }
    
    override func setFrame(_ frameRect: NSRect, display: Bool) {
        super.setFrame(frameRect, display: display)
        checkDetachment()
    }
    
    override func setFrame(_ frameRect: NSRect, display: Bool, animate: Bool) {
        super.setFrame(frameRect, display: display, animate: animate)
        checkDetachment()
    }
    
    private func checkDetachment() {
        // Check if window has been moved away from notch area
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let notchX = (screenFrame.width - self.frame.width) / 2
        let notchY = screenFrame.height - self.frame.height - 40
        let dx = abs(self.frame.origin.x - notchX)
        let dy = abs(self.frame.origin.y - notchY)
        
        let wasDetached = isDetached
        isDetached = dx > notchThreshold || dy > notchThreshold
        
        
        // If window just became detached, notify the manager to disable auto-hide
        if !wasDetached && isDetached {
            NotificationCenter.default.post(name: .dynamicIslandDetached, object: nil)
        }
        // If window was moved back to notch area, re-enable auto-hide
        else if wasDetached && !isDetached {
            NotificationCenter.default.post(name: .dynamicIslandAttached, object: nil)
        }
    }
    
    func resetToNotch() {
        isDetached = false
        positionNearNotch()
    }
    
    private func startPositionMonitoring() {
        positionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkDetachment()
        }
    }
}

extension Notification.Name {
    static let dynamicIslandMouseEntered = Notification.Name("dynamicIslandMouseEntered")
    static let dynamicIslandMouseExited = Notification.Name("dynamicIslandMouseExited")
    static let dynamicIslandDetached = Notification.Name("dynamicIslandDetached")
    static let dynamicIslandAttached = Notification.Name("dynamicIslandAttached")
}
