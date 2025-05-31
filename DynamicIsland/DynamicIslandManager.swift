import SwiftUI
import Cocoa

class DynamicIslandManager: ObservableObject {
    static let shared = DynamicIslandManager()
    
    private var window: DynamicIslandWindow?
    private var mouseMonitor = MouseEventMonitor()
    private var hideTimer: Timer?
    private var isSheetPresented = false // Track sheet presentation
    
    private init() {
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
        
        NotificationCenter.default.addObserver(
            forName: .dynamicIslandDetached,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseAutoHide() // Disable auto-hide when detached
        }
        
        NotificationCenter.default.addObserver(
            forName: .dynamicIslandAttached,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeAutoHide() // Re-enable auto-hide when back to notch
        }
        
        // Add session completion notification
        NotificationCenter.default.addObserver(
            forName: .sessionCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showDynamicIslandForSessionCompletion()
        }
        
        // Add sheet presentation notifications
        NotificationCenter.default.addObserver(
            forName: .sheetPresented,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onSheetPresented()
        }
        
        NotificationCenter.default.addObserver(
            forName: .sheetDismissed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onSheetDismissed()
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
    
    func showDynamicIslandForSessionCompletion() {
        
        // Show the Dynamic Island
        showDynamicIsland()
        
        // Switch to timer tab automatically
        UserDefaults.standard.lastSelectedTab = .timer
        
        // Extend auto-hide timer for session completion (longer display time)
        if let win = window, !win.isDetached {
            scheduleAutoHideForCompletion()
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
    
    private func scheduleAutoHideForCompletion() {
        hideTimer?.invalidate()
        // Only auto-hide if not detached
        if let win = window, win.isDetached { return }
        // Longer timer for session completion (8 seconds)
        hideTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.hideDynamicIsland()
        }
    }
    
    private func resumeAutoHide() {
        // Debug: Check window state
        if let win = window {
            print("DynamicIsland: resumeAutoHide called - isDetached: \(win.isDetached), isSheetPresented: \(isSheetPresented)")
        } else {
            print("DynamicIsland: resumeAutoHide called - no window")
        }
        
        // Don't auto-hide if detached
        if let win = window, win.isDetached {
            print("DynamicIsland: Auto-hide skipped - window is detached")
            return
        }
        
        // Don't auto-hide if a sheet is presented
        if isSheetPresented {
            print("DynamicIsland: Auto-hide skipped - sheet is presented")
            return
        }
        
        print("DynamicIsland: Scheduling auto-hide")
        scheduleAutoHide()
    }
    
    private func pauseAutoHide() {
        if let win = window {
            print("DynamicIsland: Auto-hide paused - isDetached: \(win.isDetached)")
        } else {
            print("DynamicIsland: Auto-hide paused - no window")
        }
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    private func onSheetPresented() {
        isSheetPresented = true
        pauseAutoHide()
    }
    
    private func onSheetDismissed() {
        isSheetPresented = false
        resumeAutoHide()
    }
}
