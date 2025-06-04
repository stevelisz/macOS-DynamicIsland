import SwiftUI
import Cocoa

class ExpandedWindowManager: ObservableObject {
    static let shared = ExpandedWindowManager()
    
    private var clipboardWindow: NSWindow?
    private var aiAssistantWindow: NSWindow?
    private var devToolsWindow: NSWindow?
    private var dynamicIslandWindow: NSWindow?
    private var originalDynamicIslandLevel: NSWindow.Level?
    
    private init() {}
    
    // MARK: - Dynamic Island Level Management
    
    private func lowerDynamicIslandLevel() {
        // Find the Dynamic Island window and temporarily lower its level
        for window in NSApplication.shared.windows {
            if window is DynamicIslandWindow {
                dynamicIslandWindow = window
                originalDynamicIslandLevel = window.level
                window.level = .normal // Set to normal level so expanded windows appear above
                break
            }
        }
    }
    
    private func restoreDynamicIslandLevel() {
        // Restore the Dynamic Island window to its original level
        if let window = dynamicIslandWindow, let originalLevel = originalDynamicIslandLevel {
            window.level = originalLevel
        }
        dynamicIslandWindow = nil
        originalDynamicIslandLevel = nil
    }
    
    private func hasVisibleExpandedWindow() -> Bool {
        return (clipboardWindow?.isVisible == true) ||
               (aiAssistantWindow?.isVisible == true) ||
               (devToolsWindow?.isVisible == true)
    }
    
    // MARK: - Window Creation
    
    func showClipboardWindow() {
        if clipboardWindow?.isVisible == true {
            clipboardWindow?.orderFront(nil)
            return
        }
        
        // Lower Dynamic Island level before showing expanded window
        if !hasVisibleExpandedWindow() {
            lowerDynamicIslandLevel()
        }
        
        clipboardWindow = createWindow(
            title: "Clipboard Manager",
            contentView: ExpandedClipboardView(),
            size: NSSize(width: 800, height: 600),
            minSize: NSSize(width: 600, height: 400)
        )
        
        clipboardWindow?.makeKeyAndOrderFront(nil)
    }
    
    func showAIAssistantWindow() {
        if aiAssistantWindow?.isVisible == true {
            aiAssistantWindow?.orderFront(nil)
            return
        }
        
        // Lower Dynamic Island level before showing expanded window
        if !hasVisibleExpandedWindow() {
            lowerDynamicIslandLevel()
        }
        
        aiAssistantWindow = createWindow(
            title: "AI Assistant",
            contentView: ExpandedAIAssistantView(),
            size: NSSize(width: 800, height: 700),
            minSize: NSSize(width: 600, height: 500)
        )
        
        aiAssistantWindow?.makeKeyAndOrderFront(nil)
    }
    
    func showDevToolsWindow() {
        if devToolsWindow?.isVisible == true {
            devToolsWindow?.orderFront(nil)
            return
        }
        
        // Lower Dynamic Island level before showing expanded window
        if !hasVisibleExpandedWindow() {
            lowerDynamicIslandLevel()
        }
        
        devToolsWindow = createWindow(
            title: "Developer Tools",
            contentView: ExpandedDevToolsView(),
            size: NSSize(width: 900, height: 650),
            minSize: NSSize(width: 800, height: 500)
        )
        
        devToolsWindow?.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Window Management
    
    private func createWindow<Content: View>(
        title: String,
        contentView: Content,
        size: NSSize,
        minSize: NSSize
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = true
        window.minSize = minSize
        window.center()
        
        // Use normal window level since we're managing Dynamic Island level separately
        window.level = .normal
        
        // Set up window delegate to handle cleanup when window closes
        let delegate = ExpandedWindowDelegate()
        window.delegate = delegate
        
        // Create hosting view with custom background
        let hostingView = NSHostingView(rootView: 
            ExpandedWindowContainer {
                contentView
            }
        )
        
        window.contentView = hostingView
        window.backgroundColor = NSColor.controlBackgroundColor
        
        // Add window controller for proper memory management
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        
        return window
    }
    
    func closeAllWindows() {
        clipboardWindow?.close()
        aiAssistantWindow?.close()
        devToolsWindow?.close()
        
        clipboardWindow = nil
        aiAssistantWindow = nil
        devToolsWindow = nil
        
        // Restore Dynamic Island level when all windows are closed
        restoreDynamicIslandLevel()
    }
    
    // Called when any expanded window closes
    func onWindowClosed() {
        // Clean up nil references
        if clipboardWindow?.isVisible != true {
            clipboardWindow = nil
        }
        if aiAssistantWindow?.isVisible != true {
            aiAssistantWindow = nil
        }
        if devToolsWindow?.isVisible != true {
            devToolsWindow = nil
        }
        
        // If no expanded windows are visible, restore Dynamic Island level
        if !hasVisibleExpandedWindow() {
            restoreDynamicIslandLevel()
        }
    }
}

// MARK: - Window Delegate

class ExpandedWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Notify the manager that a window is closing
        ExpandedWindowManager.shared.onWindowClosed()
    }
}

// MARK: - Expanded Window Container

struct ExpandedWindowContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
    }
} 