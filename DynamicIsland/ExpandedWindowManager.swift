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
        // Find the Dynamic Island window and hide it
        for window in NSApplication.shared.windows {
            if window is DynamicIslandWindow {
                dynamicIslandWindow = window
                originalDynamicIslandLevel = window.level
                // Hide the Dynamic Island window when expanded windows are shown
                window.orderOut(nil)
                break
            }
        }
    }
    
    private func restoreDynamicIslandLevel() {
        // Always search for the Dynamic Island window fresh in case references changed
        for window in NSApplication.shared.windows {
            if window is DynamicIslandWindow {
                // Restore the window level if we have it stored, otherwise use floating level
                let levelToRestore = originalDynamicIslandLevel ?? .floating
                window.level = levelToRestore
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
        // Clear the stored references after use
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
        // Clean up any closed window references first
        cleanupClosedWindows()
        
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
            size: NSSize(width: 900, height: 700),
            minSize: NSSize(width: 400, height: 300)
        )
        
        clipboardWindow?.makeKeyAndOrderFront(nil)
    }
    
    func showAIAssistantWindow() {
        // Clean up any closed window references first
        cleanupClosedWindows()
        
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
        // Clean up any closed window references first
        cleanupClosedWindows()
        
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
            size: NSSize(width: 800, height: 600),
            minSize: NSSize(width: 700, height: 500)
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
        
        // Start at floating level to pop up on top of everything
        window.level = .floating
        
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
        
        // After a brief moment, lower to normal level so it doesn't stay always on top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            window.level = .normal
        }
        
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
    
    // Clean up references to closed windows
    private func cleanupClosedWindows() {
        if clipboardWindow?.isVisible != true {
            clipboardWindow = nil
        }
        if aiAssistantWindow?.isVisible != true {
            aiAssistantWindow = nil
        }
        if devToolsWindow?.isVisible != true {
            devToolsWindow = nil
        }
    }
    
    // Called when any expanded window closes
    func onWindowClosed() {
        // Use a small delay to ensure window is fully closed before cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cleanupClosedWindows()
            
            // If no expanded windows are visible, restore Dynamic Island level
            if !(self?.hasVisibleExpandedWindow() ?? false) {
                self?.restoreDynamicIslandLevel()
            }
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