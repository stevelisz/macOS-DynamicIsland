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
                        case .calendar:
                            CalendarView()
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
        case .calendar: return "Calendar & Time"
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
        case .clipboard, .aiAssistant, .developerTools, .calendar:
            return true
        default:
            return false
        }
    }
    
    private func openExpandedWindow(for viewType: MainViewType) {
        // Hide the Dynamic Island immediately when expand is clicked
        closeDynamicIsland()
        
        switch viewType {
        case .clipboard:
            ExpandedWindowManager.shared.showClipboardWindow()
        case .aiAssistant:
            ExpandedWindowManager.shared.showAIAssistantWindow()
        case .developerTools:
            ExpandedWindowManager.shared.showDevToolsWindow()
        case .calendar:
            ExpandedWindowManager.shared.showCalendarWindow()
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
    case calendar
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
    
    // High-performance data structures for O(1) operations
    private var itemsDict: [String: ClipboardItem] = [:]  // contentHash -> item
    private var orderedItems: [ClipboardItem] = []        // Ordered list for UI
    private let maxItems = 100  // Hard limit to prevent memory issues
    
    // Background processing
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let processingQueue = DispatchQueue(label: "clipboard.processing", qos: .utility)
    private let userDefaultsKey = "clipboardHistory"
    
    // Rate limiting & debouncing
    private var isProcessing = false
    private var pendingOperations: [() -> Void] = []
    private let rateLimitDelay: TimeInterval = 0.1  // 100ms minimum between operations
    private var lastProcessTime = Date()
    
    init() {
        load()
    }
    
    func start() {
        // High-frequency timer for responsiveness, but with rate limiting
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkClipboard()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - O(1) Operations
    
    @MainActor
    private func checkClipboard() async {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        guard !isProcessing else { return }  // Skip if already processing
        
        lastChangeCount = pb.changeCount
        isProcessing = true
        
        // Rate limiting - ensure minimum delay between operations
        let timeSinceLastProcess = Date().timeIntervalSince(lastProcessTime)
        if timeSinceLastProcess < rateLimitDelay {
            try? await Task.sleep(nanoseconds: UInt64((rateLimitDelay - timeSinceLastProcess) * 1_000_000_000))
        }
        
        // Process in background to never block main thread
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.processClipboardChange(pasteboard: pb)
            }
        }
        
        lastProcessTime = Date()
        isProcessing = false
    }
    
    private func processClipboardChange(pasteboard: NSPasteboard) async {
        guard let types = pasteboard.types else { return }
        
        // Determine item type and extract data
        let clipboardData: (type: ClipboardItemType, content: String?, data: Data?, urls: [URL])?
        
        // 1. File URLs (handle bulk operations efficiently)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            clipboardData = (.file, nil, nil, urls)
        }
        // 2. Images
        else if types.contains(.tiff), let data = pasteboard.data(forType: .tiff) {
            clipboardData = (.image, nil, data, [])
        }
        // 3. Text
        else if types.contains(.string), let str = pasteboard.string(forType: .string), !str.isEmpty {
            clipboardData = (.text, str, nil, [])
        }
        else {
            return
        }
        
        guard let clipData = clipboardData else { return }
        
        // Process based on type
        switch clipData.type {
        case .file:
            await handleFileItems(clipData.urls)
        case .image:
            if let data = clipData.data {
                await handleImageItem(data)
            }
        case .text:
            if let content = clipData.content {
                await handleTextItem(content)
            }
        }
    }
    
    // MARK: - Specialized Handlers (All Async)
    
    private func handleFileItems(_ urls: [URL]) async {
        // Handle bulk file operations efficiently
        let batchSize = 10  // Process in batches to prevent overwhelming
        
        for batch in urls.chunked(into: batchSize) {
            await withTaskGroup(of: ClipboardItem?.self) { group in
                for url in batch {
                    group.addTask {
                        return await self.createFileItem(url)
                    }
                }
                
                var newItems: [ClipboardItem] = []
                for await item in group {
                    if let item = item {
                        newItems.append(item)
                    }
                }
                
                // Batch insert for efficiency
                await MainActor.run {
                    self.batchInsert(newItems)
                }
            }
        }
    }
    
    private func handleImageItem(_ data: Data) async {
        let item = await createImageItem(data)
        await MainActor.run {
            self.insertItem(item)
        }
    }
    
    private func handleTextItem(_ content: String) async {
        let item = createTextItem(content)
        await MainActor.run {
            self.insertItem(item)
        }
    }
    
    // MARK: - Item Creation (Background)
    
    private func createTextItem(_ content: String) -> ClipboardItem {
        return ClipboardItem(
            id: UUID(),
            type: .text,
            content: content,
            date: Date(),
            pinned: false
        )
    }
    
    private func createImageItem(_ data: Data) async -> ClipboardItem {
        return ClipboardItem(
            id: UUID(),
            type: .image,
            imageData: data,
            date: Date(),
            pinned: false
        )
    }
    
    private func createFileItem(_ url: URL) async -> ClipboardItem? {
        // Check if file is accessible before creating item
        guard url.isFileURL && FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        return ClipboardItem(
            id: UUID(),
            type: .file,
            fileURL: url,
            date: Date(),
            pinned: false
        )
    }
    
    // MARK: - O(1) Insertion & Deduplication
    
    @MainActor
    private func insertItem(_ item: ClipboardItem) {
        // O(1) deduplication check
        if let existingItem = itemsDict[item.contentHash] {
            // Update existing item's date and move to top
            var updatedItem = existingItem
            updatedItem.date = Date()
            
            // Remove from current position O(n) - could optimize with linked list
            orderedItems.removeAll { $0.id == existingItem.id }
            // Insert at front O(1)
            orderedItems.insert(updatedItem, at: 0)
            itemsDict[item.contentHash] = updatedItem
        } else {
            // Insert new item O(1)
            orderedItems.insert(item, at: 0)
            itemsDict[item.contentHash] = item
        }
        
        // Enforce size limit
        while orderedItems.count > maxItems {
            if let removedItem = orderedItems.popLast() {
                itemsDict.removeValue(forKey: removedItem.contentHash)
            }
        }
        
        // Update published array
        items = orderedItems
        save()
    }
    
    @MainActor
    private func batchInsert(_ newItems: [ClipboardItem]) {
        for item in newItems {
            // O(1) deduplication check
            if itemsDict[item.contentHash] == nil {
                orderedItems.insert(item, at: 0)
                itemsDict[item.contentHash] = item
            }
        }
        
        // Enforce size limit
        while orderedItems.count > maxItems {
            if let removedItem = orderedItems.popLast() {
                itemsDict.removeValue(forKey: removedItem.contentHash)
            }
        }
        
        // Update published array
        items = orderedItems
        save()
    }
    
    // MARK: - Public Operations (All O(1) or optimized)
    
    func pin(_ item: ClipboardItem) {
        Task { @MainActor in
            if let index = orderedItems.firstIndex(where: { $0.id == item.id }) {
                orderedItems[index].pinned = true
                itemsDict[item.contentHash]?.pinned = true
                items = orderedItems
                save()
            }
        }
    }
    
    func unpin(_ item: ClipboardItem) {
        Task { @MainActor in
            if let index = orderedItems.firstIndex(where: { $0.id == item.id }) {
                orderedItems[index].pinned = false
                itemsDict[item.contentHash]?.pinned = false
                items = orderedItems
                save()
            }
        }
    }
    
    func remove(_ item: ClipboardItem) {
        Task { @MainActor in
            orderedItems.removeAll { $0.id == item.id }
            itemsDict.removeValue(forKey: item.contentHash)
            items = orderedItems
            save()
        }
    }
    
    func clearAll() {
        Task { @MainActor in
            orderedItems.removeAll()
            itemsDict.removeAll()
            items = []
            save()
        }
    }
    
    // MARK: - Persistence (Background)
    
    private func save() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.orderedItems) {
                UserDefaults.standard.set(data, forKey: self.userDefaultsKey)
            }
        }
    }
    
    private func load() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            if let data = UserDefaults.standard.data(forKey: self.userDefaultsKey),
               let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
                
                await MainActor.run {
                    self.orderedItems = decoded
                    self.itemsDict = Dictionary(uniqueKeysWithValues: decoded.map { ($0.contentHash, $0) })
                    self.items = self.orderedItems
                }
            }
        }
    }
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
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

