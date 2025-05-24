import SwiftUI
import Cocoa

class DynamicIslandWindow: NSPanel {
    private var trackingArea: NSTrackingArea?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 140),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Window appearance
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        // Remove the shadowStyle line - this property doesn't exist
        
        // Window behavior
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isMovable = false
        self.acceptsMouseMovedEvents = true
        
        // Positioning
        self.hidesOnDeactivate = false
        self.animationBehavior = .none
        
        // Make sure it appears above everything
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)) + 1)
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
    
    override var canBecomeKey: Bool { false }
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
}

extension Notification.Name {
    static let dynamicIslandMouseEntered = Notification.Name("dynamicIslandMouseEntered")
    static let dynamicIslandMouseExited = Notification.Name("dynamicIslandMouseExited")
}
