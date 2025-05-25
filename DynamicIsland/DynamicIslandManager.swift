import SwiftUI
import Cocoa

class DynamicIslandManager: ObservableObject {
    private var window: DynamicIslandWindow?
    private var mouseMonitor = MouseEventMonitor()
    private var hideTimer: Timer?
    
    init() {
        setupNotifications()
        mouseMonitor.startMonitoring()
    }
    
    deinit {
        mouseMonitor.stopMonitoring()
        hideTimer?.invalidate()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .notchClicked,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.toggleDynamicIsland()
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeDynamicIsland,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hideDynamicIsland()
        }
        
        NotificationCenter.default.addObserver(
            forName: .notchFileDragEntered,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showDynamicIsland()
        }
        
        NotificationCenter.default.addObserver(
            forName: .dynamicIslandMouseEntered,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseAutoHide()
        }
        NotificationCenter.default.addObserver(
            forName: .dynamicIslandMouseExited,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeAutoHide()
        }
    }
    
    func toggleDynamicIsland() {
        if let win = window {
            if win.isDetached {
                // If detached, just close
                hideDynamicIsland()
            } else {
                hideDynamicIsland()
            }
        } else {
            showDynamicIsland()
        }
    }
    
    func showDynamicIsland() {
        // Don't show if already visible
        guard window == nil else { return }
        
        // Create and configure window
        window = DynamicIslandWindow()
        
        // Set up SwiftUI content
        let contentView = NSHostingView(rootView: DynamicIslandView())
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        window?.contentView = contentView
        if let win = window, !win.isDetached {
            win.resetToNotch()
        }
        
        // Show with animation
        window?.alphaValue = 0
        window?.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window?.animator().alphaValue = 1.0
        }
        
        // Set up auto-hide timer only if not detached
        if let win = window, !win.isDetached {
            scheduleAutoHide()
        }
    }
    
    func hideDynamicIsland() {
        guard let window = window else { return }
        
        hideTimer?.invalidate()
        hideTimer = nil
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            self.window = nil
        })
    }
    
    private func scheduleAutoHide() {
        hideTimer?.invalidate()
        // Only auto-hide if not detached
        if let win = window, win.isDetached { return }
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.hideDynamicIsland()
        }
    }
    
    private func pauseAutoHide() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    private func resumeAutoHide() {
        // Only auto-hide if not detached
        if let win = window, win.isDetached { return }
        scheduleAutoHide()
    }
}
