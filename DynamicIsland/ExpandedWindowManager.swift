import SwiftUI
import Cocoa

class ExpandedWindowManager: ObservableObject {
    static let shared = ExpandedWindowManager()
    
    private var clipboardWindow: NSWindow?
    private var aiAssistantWindow: NSWindow?
    private var devToolsWindow: NSWindow?
    
    private init() {}
    
    // MARK: - Window Creation
    
    func showClipboardWindow() {
        if clipboardWindow?.isVisible == true {
            clipboardWindow?.orderFront(nil)
            return
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
        
        // Set window level above the Dynamic Island window
        // Dynamic Island uses: NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)) + 1)
        // So we use +2 to appear above it
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)) + 2)
        
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