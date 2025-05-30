import SwiftUI
import Cocoa

class DynamicIslandWindow: NSPanel {
    private var trackingArea: NSTrackingArea?
    var isDetached: Bool = false
    private let notchThreshold: CGFloat = 10 // px
    private let headerHeight: CGFloat = 110 // Should match SwiftUI header
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 140),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView, .resizable],
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
        self.isMovable = true
        self.isMovableByWindowBackground = false
        self.acceptsMouseMovedEvents = true
        
        // Positioning
        self.hidesOnDeactivate = false
        self.animationBehavior = .none
        
        // Make sure it appears above everything
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)) + 1)

        // Add draggable header view
        let dragView = DraggableHeaderView(frame: NSRect(x: 0, y: self.frame.height - headerHeight, width: self.frame.width, height: headerHeight))
        dragView.autoresizingMask = [.width, .minYMargin]
        self.contentView?.addSubview(dragView)
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
        // If the window is moved away from the notch area, mark as detached
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let notchX = (screenFrame.width - self.frame.width) / 2
        let notchY = screenFrame.height - self.frame.height - 40
        let dx = abs(point.x - notchX)
        let dy = abs(point.y - notchY)
        if dx > notchThreshold || dy > notchThreshold {
            isDetached = true
        }
    }
    
    func resetToNotch() {
        isDetached = false
        positionNearNotch()
    }
}

extension Notification.Name {
    static let dynamicIslandMouseEntered = Notification.Name("dynamicIslandMouseEntered")
    static let dynamicIslandMouseExited = Notification.Name("dynamicIslandMouseExited")
}

// Transparent NSView for header drag region
class DraggableHeaderView: NSView {
    override func mouseDown(with event: NSEvent) {
        self.window?.performDrag(with: event)
    }
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always allow mouse events to pass through except for drag
        return self
    }
    override func draw(_ dirtyRect: NSRect) {
        // Transparent
    }
}
