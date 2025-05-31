import SwiftUI
import ServiceManagement

@main
struct DynamicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We don't want a regular window, so we use Settings which is hidden
        Settings {
            EmptyView()
        }
    }
}

// Create AppDelegate to handle the app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the dock and menu bar
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize our Dynamic Island manager (singleton pattern)
        _ = DynamicIslandManager.shared
        
        // Show Dynamic Island automatically on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DynamicIslandManager.shared.showDynamicIsland()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running even when no windows are open
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            DynamicIslandManager.shared.showDynamicIsland()
        }
        return true
    }
}
