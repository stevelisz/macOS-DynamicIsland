import SwiftUI

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
    var dynamicIslandManager: DynamicIslandManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the dock and menu bar
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize our Dynamic Island manager
        dynamicIslandManager = DynamicIslandManager()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running even when no windows are open
    }
}
