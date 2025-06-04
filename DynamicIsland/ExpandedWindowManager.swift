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
            size: NSSize(width: 800, height: 600)
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
            size: NSSize(width: 900, height: 700)
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
            size: NSSize(width: 1000, height: 800)
        )
        
        devToolsWindow?.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Window Management
    
    private func createWindow<Content: View>(
        title: String,
        contentView: Content,
        size: NSSize
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        
        // Create hosting view with custom background
        let hostingView = NSHostingView(rootView: 
            ExpandedWindowContainer {
                contentView
            }
        )
        
        window.contentView = hostingView
        window.backgroundColor = .clear
        
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
        ZStack {
            // Background with blur effect
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom title bar
                ExpandedWindowTitleBar()
                
                // Content area
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Custom Title Bar

struct ExpandedWindowTitleBar: View {
    var body: some View {
        HStack {
            // Return to Dynamic Island button
            Button(action: {
                returnToDynamicIsland()
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back to Island")
                        .font(DesignSystem.Typography.captionMedium)
                }
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(.ultraThinMaterial)
    }
    
    private func returnToDynamicIsland() {
        // Close current window and show Dynamic Island
        if let window = NSApp.keyWindow {
            window.close()
        }
        
        // Show Dynamic Island
        DynamicIslandManager.shared.showDynamicIsland()
    }
}

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
} 