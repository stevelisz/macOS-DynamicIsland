import SwiftUI
import AppKit
import Foundation
import Combine
import ServiceManagement

struct DynamicIslandView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showFilesPopover = false
    @State private var mediaInfo: MediaInfo? = nil
    @State private var quickApps: [URL] = UserDefaults.standard.quickApps
    @State private var clipboardItems: [ClipboardItem] = []
    @State private var isDropTargeted = false
    @State private var showDropPulse = false
    @State private var selectedView: MainViewType = UserDefaults.standard.lastSelectedTab
    @State private var enabledTabs: Set<MainViewType> = UserDefaults.standard.enabledTabs
    @State private var isPopped: Bool = false
    @StateObject private var clipboardWatcher = GlobalClipboardWatcher.shared
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main container with improved glassmorphism
            RoundedRectangle(cornerRadius: isPopped ? DesignSystem.BorderRadius.xxl : 60, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: isPopped ? DesignSystem.BorderRadius.xxl : 60, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.18))
                        .blur(radius: DesignSystem.Spacing.lg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isPopped ? DesignSystem.BorderRadius.xxl : 60, style: .continuous)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1.2)
                )
                .shadow(
                    color: DesignSystem.Shadows.xl.color,
                    radius: DesignSystem.Shadows.xl.radius,
                    x: DesignSystem.Shadows.xl.x,
                    y: DesignSystem.Shadows.xl.y
                )
                .shadow(color: DesignSystem.Colors.primary.opacity(0.08), radius: 8, x: 0, y: 2)
                .scaleEffect(isPopped ? 1.0 : 0.7, anchor: .top)
                .opacity(isPopped ? 1.0 : 0.0)
                .animation(DesignSystem.Animation.bounce, value: isPopped)
            
            // Drop target indicator
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xxl, style: .continuous)
                .stroke(isDropTargeted ? DesignSystem.Colors.primary.opacity(0.7) : Color.clear, lineWidth: isDropTargeted ? 4 : 0)
                .shadow(color: isDropTargeted ? DesignSystem.Colors.primary.opacity(0.3) : .clear, radius: DesignSystem.Spacing.lg, x: 0, y: 4)
                .scaleEffect(showDropPulse ? 1.08 : 1.0)
                .opacity(isDropTargeted || showDropPulse ? 1 : 0)
                .animation(DesignSystem.Animation.bounce, value: isDropTargeted)
                .animation(DesignSystem.Animation.smooth, value: showDropPulse)
            
            VStack(spacing: 0) {
                // Window drag handle area - invisible but draggable
                WindowDragArea()
                    .frame(height: 20) // Small drag area at the top
                
                // Top controls - positioned at the very top with safe padding
                headerControls
                
                // Enhanced Tab Navigation
                ModernTabBar(selectedView: $selectedView, enabledTabs: $enabledTabs)
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
                    .padding(.top, DesignSystem.Spacing.micro)
                    .padding(.bottom, DesignSystem.Spacing.xs)
                
                // Separator
                Rectangle()
                    .fill(DesignSystem.Colors.border)
                    .frame(height: 1)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.micro)
                
                // Section title with minimal spacing
                HStack {
                    Text(sectionTitle)
                        .font(DesignSystem.Typography.headline3)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(.leading, DesignSystem.Spacing.xl)
                        .padding(.top, DesignSystem.Spacing.micro)
                        .padding(.bottom, DesignSystem.Spacing.sm)
                    
                    // Expand button for supported tabs
                    if shouldShowExpandButton(for: selectedView) {
                        Button(action: {
                            openExpandedWindow(for: selectedView)
                        }) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 10, weight: .medium))
                                Text("Expand")
                                    .font(DesignSystem.Typography.micro)
                            }
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, DesignSystem.Spacing.xxs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, DesignSystem.Spacing.micro)
                        .padding(.bottom, DesignSystem.Spacing.sm)
                    }
                    
                    Spacer()
                }
                
                // Content Area with scroll capability
                ScrollView {
                    Group {
                        switch selectedView {
                        case .clipboard:
                            ClipboardManagerGallery(clipboardItems: $clipboardWatcher.items)
                        case .quickApp:
                            QuickAppGallery(quickApps: $quickApps)
                                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                                    handleAppDrop(providers: providers)
                                }
                        case .systemMonitor:
                            SystemMonitorView()
                        case .weather:
                            WeatherView()
                        case .timer:
                            TimerView()
                        case .unitConverter:
                            UnitConverterView()
                        case .developerTools:
                            DeveloperToolsView()
                        case .aiAssistant:
                            AIAssistantView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.micro)
                    .animation(DesignSystem.Animation.smooth, value: selectedView)
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 310)
            }
        }
        .frame(width: 360, height: 450)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xxl, style: .continuous))
        .clipped()
        .onAppear {
            withAnimation(DesignSystem.Animation.bounce) {
                isPopped = true
            }
            quickApps = UserDefaults.standard.quickApps
            clipboardWatcher.start()
        }
        .onDisappear {
            withAnimation(DesignSystem.Animation.bounce) {
                isPopped = false
            }
            clipboardWatcher.stop()
        }
        .onChange(of: quickApps) { _, newValue in
            UserDefaults.standard.quickApps = newValue
        }
        .onChange(of: selectedView) { _, newValue in
            UserDefaults.standard.lastSelectedTab = newValue
        }
        .onChange(of: enabledTabs) { _, newValue in
            UserDefaults.standard.enabledTabs = newValue
            // Ensure selected view is still enabled
            if !newValue.contains(selectedView) {
                selectedView = newValue.first ?? .clipboard
            }
        }
    }
    
    private var headerControls: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Spacer()
            
            // Tab Selector Dropdown - positioned to the left of control icons
            TabSelectorDropdown(selectedView: $selectedView, enabledTabs: $enabledTabs)
            
            // Settings Menu
            HeaderMenuButton(
                icon: "gearshape",
                color: DesignSystem.Colors.textSecondary
            ) {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(enabled: newValue)
                    }
                
                Divider()
                
                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:") {
                        NSWorkspace.shared.open(url)
                    } else {
                        let settingsURL = URL(fileURLWithPath: "/System/Applications/System Preferences.app")
                        NSWorkspace.shared.open(settingsURL)
                    }
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(DesignSystem.Colors.system)
                        Text("System Settings")
                            .font(DesignSystem.Typography.body)
                    }
                }
                
                Button(action: {
                    let activityMonitorURL = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
                    NSWorkspace.shared.open(activityMonitorURL)
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(DesignSystem.Colors.success)
                        Text("Activity Monitor")
                            .font(DesignSystem.Typography.body)
                    }
                }
                
                Button(action: {
                    let terminalURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
                    NSWorkspace.shared.open(terminalURL)
                }) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text("Terminal")
                            .font(DesignSystem.Typography.body)
                    }
                }
            }
            
            // Power/Quit button
            HeaderButton(
                icon: "power",
                color: DesignSystem.Colors.error,
                action: quitApplication
            )
            
            // Close button - properly spaced
            HeaderButton(
                icon: "xmark",
                color: DesignSystem.Colors.textSecondary,
                action: closeDynamicIsland
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.xxl)
        .padding(.top, DesignSystem.Spacing.micro)
        .padding(.bottom, DesignSystem.Spacing.xs)
    }
    
    private var sectionTitle: String {
        switch selectedView {
        case .clipboard: return "History"
        case .quickApp: return "Quick Apps"
        case .systemMonitor: return "System Usage"
        case .weather: return "Weather"
        case .timer: return "Timer"
        case .unitConverter: return "Unit Converter"
        case .developerTools: return "Developer Tools"
        case .aiAssistant: return "AI Assistant"
        }
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            
        }
    }
    
    private func handleAppDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil), url.pathExtension == "app" {
                        DispatchQueue.main.async {
                            if !quickApps.contains(url) {
                                quickApps.append(url)
                            }
                        }
                    } else if let url = item as? URL, url.pathExtension == "app" {
                        DispatchQueue.main.async {
                            if !quickApps.contains(url) {
                                quickApps.append(url)
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func closeDynamicIsland() {
        NotificationCenter.default.post(name: .closeDynamicIsland, object: nil)
    }
    
    private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Expanded Window Functions
    
    private func shouldShowExpandButton(for viewType: MainViewType) -> Bool {
        switch viewType {
        case .clipboard, .aiAssistant, .developerTools:
            return true
        default:
            return false
        }
    }
    
    private func openExpandedWindow(for viewType: MainViewType) {
        switch viewType {
        case .clipboard:
            ExpandedWindowManager.shared.showClipboardWindow()
        case .aiAssistant:
            ExpandedWindowManager.shared.showAIAssistantWindow()
        case .developerTools:
            ExpandedWindowManager.shared.showDevToolsWindow()
        default:
            break
        }
    }
}

enum MainViewType: CaseIterable, Codable, Transferable {
    case clipboard
    case quickApp
    case systemMonitor
    case weather
    case timer
    case unitConverter
    case developerTools
    case aiAssistant
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

class GlobalClipboardWatcher: ClipboardWatcher {
    static let shared = GlobalClipboardWatcher()
    private override init() {
        super.init()
        start()
    }
}

class ClipboardWatcher: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var pinnedItems: [ClipboardItem] = []
    private let userDefaultsKey = "clipboardHistory"
    init() {
        load()
    }
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        if let types = pb.types {
            // 1. File URLs
            if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
                for url in urls {
                    addItem(.init(id: UUID(), type: .file, content: nil, imageData: nil, fileURL: url, date: Date(), pinned: false))
                }
            }
            // 2. Images
            else if types.contains(.tiff), let data = pb.data(forType: .tiff) {
                addItem(.init(id: UUID(), type: .image, content: nil, imageData: data, fileURL: nil, date: Date(), pinned: false))
            }
            // 3. Text
            else if types.contains(.string), let str = pb.string(forType: .string), !str.isEmpty {
                addItem(.init(id: UUID(), type: .text, content: str, imageData: nil, fileURL: nil, date: Date(), pinned: false))
            }
        }
    }
    private func addItem(_ item: ClipboardItem) {
        // Only allow each distinct item once. If same, update date and move to top.
        if item.type == .image, let newHash = item.imagePixelHash {
            if let idx = items.firstIndex(where: { $0.type == .image && $0.imagePixelHash == newHash }) {
                // Update date and move to top
                var updated = items[idx]
                updated.date = Date()
                items.remove(at: idx)
                items.insert(updated, at: 0)
                save()
                return
            }
        } else if let idx = items.firstIndex(where: { $0.type == item.type && $0.content == item.content && $0.fileURL == item.fileURL && $0.imageData == item.imageData }) {
            // Update date and move to top
            var updated = items[idx]
            updated.date = Date()
            items.remove(at: idx)
            items.insert(updated, at: 0)
            save()
            return
        }
        items.insert(item, at: 0)
        save()
    }
    func pin(_ item: ClipboardItem) {
        if let idx = items.firstIndex(of: item) {
            items[idx].pinned = true
            save()
        }
    }
    func unpin(_ item: ClipboardItem) {
        if let idx = items.firstIndex(of: item) {
            items[idx].pinned = false
            save()
        }
    }
    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        save()
    }
    func clearAll() {
        items.removeAll()
        save()
    }
    private func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(items) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
        }
    }
}

// MARK: - Window Drag Handle
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DragHandleView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed
    }
}

class DragHandleView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw nothing - invisible drag area
    }
    
    override func mouseDown(with event: NSEvent) {
        // Let the window handle the dragging
        window?.performDrag(with: event)
    }
}

