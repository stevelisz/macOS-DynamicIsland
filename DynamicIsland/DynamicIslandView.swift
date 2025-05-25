import SwiftUI
import AppKit
import Darwin
import IOKit

struct DynamicIslandView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showActionsPopover = false
    @State private var showFilesPopover = false
    @State private var mediaInfo: MediaInfo? = nil
    @State private var quickFiles: [URL] = UserDefaults.standard.quickFiles
    @State private var quickActionIndex: Int = 0
    @State private var isAnimatingQuickAction = false
    @State private var isCarouselCooldown = false
    @State private var lastQuickActionIndex = 0
    @State private var carouselDirection: Int = 0 // -1 for left, 1 for right
    @State private var carouselDragOffset: CGFloat = 0
    @State private var showCarouselArrows = false
    @State private var carouselArrowHideTask: DispatchWorkItem?
    @State private var isDropTargeted = false
    @State private var showDropPulse = false
    @State private var selectedView: MainViewType = .systemMonitor
    @State private var isPopped: Bool = false // For pop animation
    
    var body: some View {
        ZStack {
            // Main island container with enhanced blur and shadow
            RoundedRectangle(cornerRadius: isPopped ? 32 : 60, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: isPopped ? 32 : 60, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.18))
                        .blur(radius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isPopped ? 32 : 60, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
                )
                .frame(width: 340, height: 380)
                .shadow(color: Color.black.opacity(0.25), radius: 32, x: 0, y: 16)
                .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 2)
                .scaleEffect(isPopped ? 1.0 : 0.7, anchor: .top)
                .opacity(isPopped ? 1.0 : 0.0)
                .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isPopped)
            // Drop feedback overlay
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(isDropTargeted ? Color.accentColor.opacity(0.7) : Color.clear, lineWidth: isDropTargeted ? 4 : 0)
                .shadow(color: isDropTargeted ? Color.accentColor.opacity(0.3) : .clear, radius: 16, x: 0, y: 4)
                .scaleEffect(showDropPulse ? 1.08 : 1.0)
                .opacity(isDropTargeted || showDropPulse ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDropTargeted)
                .animation(.easeOut(duration: 0.2), value: showDropPulse)
            VStack(spacing: 0) {
                // Fixed header
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Button(action: {
                            if let url = URL(string: "x-apple-weather://"), NSWorkspace.shared.open(url) {
                                // Opened Weather app
                            } else if let webUrl = URL(string: "https://weather.com") {
                                NSWorkspace.shared.open(webUrl)
                            }
                        }) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Open Weather app")
                        Button(action: {
                            let calendarURL = URL(fileURLWithPath: "/System/Applications/Calendar.app")
                            NSWorkspace.shared.open(calendarURL)
                        }) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Open Calendar app")
                        Button(action: {
                            if let url = URL(string: "https://www.google.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Search Google")
                        Spacer()
                        // New icon for actions popover
                        Button(action: { showActionsPopover.toggle() }) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(Color.accentColor)
                                .background(Color.clear)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                        .popover(isPresented: $showActionsPopover, arrowEdge: .top) {
                            VStack(spacing: 0) {
                                Text("Quick Actions")
                                    .font(.headline)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                                Divider()
                                VStack(spacing: 8) {
                                    quickActionRow(
                                        "System Settings",
                                        icon: "gearshape.fill",
                                        color: LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                                    ) {
                                        openSystemSettings()
                                        showActionsPopover = false
                                    }
                                    quickActionRow(
                                        "Activity Monitor",
                                        icon: "speedometer",
                                        color: LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                                    ) {
                                        openActivityMonitor()
                                        showActionsPopover = false
                                    }
                                    quickActionRow(
                                        "Terminal",
                                        icon: "terminal.fill",
                                        color: LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                                    ) {
                                        openTerminal()
                                        showActionsPopover = false
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                            }
                            .frame(width: 220)
                        }
                        Button(action: closeDynamicIsland) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(Color.secondary.opacity(0.7))
                                .background(Color.clear)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    // View switcher
                    HStack(spacing: 16) {
                        Button(action: { selectedView = .systemMonitor }) {
                            Image(systemName: "gauge.high")
                                .font(.title3)
                                .foregroundColor(selectedView == .systemMonitor ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        Button(action: { selectedView = .quickFiles }) {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(selectedView == .quickFiles ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
                    // Divider between header/switcher and main content
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }
                .frame(height: 120) // Slightly larger fixed height for header + switcher + divider
                // Main content area fills the rest of the window
                Group {
                    switch selectedView {
                    case .systemMonitor:
                        SystemMonitorView()
                    case .quickFiles:
                        QuickFilesGallery(quickFiles: $quickFiles)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 340, height: 380)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                isPopped = true
            }
            print("Triggering AppleScript for permission prompt")
//            _ = getSpotifyInfo()
//            _ = getAppleMusicInfo()
//            updateMediaInfo()
            // Load quick files from UserDefaults
            quickFiles = UserDefaults.standard.quickFiles
            // Poll for media info every 2 seconds
//            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
//                updateMediaInfo()
//            }
        }
        .onDisappear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                isPopped = false
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: UUID())
        // Save quickFiles to UserDefaults whenever it changes
        .onChange(of: quickFiles) { _, newValue in
            UserDefaults.standard.quickFiles = newValue
        }
        .onDrop(of: ["public.file-url"], isTargeted: $isDropTargeted) { providers in
            let result = handleFileDrop(providers: providers)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDropPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation { showDropPulse = false }
            }
            return result
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            if !quickFiles.contains(url) {
                                quickFiles.append(url)
                            }
                        }
                    } else if let url = item as? URL {
                        DispatchQueue.main.async {
                            if !quickFiles.contains(url) {
                                quickFiles.append(url)
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func quickActionRow(
        _ title: String,
        icon: String,
        color: LinearGradient,
        action: @escaping () -> Void
    ) -> some View {
        HoverableButton(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.secondary.opacity(0.7))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Media Control Logic
    private func updateMediaInfo() {
        // Try Apple Music first
        if let info = getAppleMusicInfo() {
            self.mediaInfo = info
            return
        }
        // Then try Spotify
        if let info = getSpotifyInfo() {
            self.mediaInfo = info
            return
        }
        // No media playing
        self.mediaInfo = nil
    }

    private func getAppleMusicInfo() -> MediaInfo? {
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set isPlaying to (player state is playing)
                    return trackName & "|||" & artistName & "|||" & (isPlaying as string)
                end if
            end tell
        end if
        """
        if let result = runAppleScript(script) {
            let parts = result.components(separatedBy: "|||")
            if parts.count == 3 {
                return MediaInfo(app: "Music", title: parts[0], artist: parts[1], isPlaying: parts[2] == "true")
            }
        }
        return nil
    }

    private func getSpotifyInfo() -> MediaInfo? {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set isPlaying to (player state is playing)
                    return trackName & "|||" & artistName & "|||" & (isPlaying as string)
                end if
            end tell
        end if
        """
        if let result = runAppleScript(script) {
            let parts = result.components(separatedBy: "|||")
            if parts.count == 3 {
                return MediaInfo(app: "Spotify", title: parts[0], artist: parts[1], isPlaying: parts[2] == "true")
            }
        }
        return nil
    }

    private func runAppleScript(_ script: String) -> String? {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum MediaControlAction {
        case playPause, next, previous, stop
    }

    private func handleMediaControl(_ action: MediaControlAction) {
        guard let info = mediaInfo else { return }
        let app = info.app
        var script = ""
        switch (app, action) {
        case ("Music", .playPause):
            script = "tell application \"Music\" to playpause"
        case ("Music", .next):
            script = "tell application \"Music\" to next track"
        case ("Music", .previous):
            script = "tell application \"Music\" to previous track"
        case ("Music", .stop):
            script = "tell application \"Music\" to stop"
        case ("Spotify", .playPause):
            script = "tell application \"Spotify\" to playpause"
        case ("Spotify", .next):
            script = "tell application \"Spotify\" to next track"
        case ("Spotify", .previous):
            script = "tell application \"Spotify\" to previous track"
        case ("Spotify", .stop):
            script = "tell application \"Spotify\" to pause"
        default:
            return
        }
        _ = runAppleScript(script)
        // Refresh info after control
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            updateMediaInfo()
        }
    }
    
    // MARK: - Actions
    private func closeDynamicIsland() {
        NotificationCenter.default.post(name: .closeDynamicIsland, object: nil)
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
        }
        closeDynamicIsland()
    }
    
    private func openActivityMonitor() {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"), configuration: configuration) { _, _ in }
        closeDynamicIsland()
    }
    
    private func openTerminal() {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"), configuration: configuration) { _, _ in }
        closeDynamicIsland()
    }
}

// MARK: - Media Info Model and View
struct MediaInfo {
    let app: String // "Music" or "Spotify"
    let title: String
    let artist: String
    let isPlaying: Bool
}

struct MediaControlView: View {
    let mediaInfo: MediaInfo
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mediaInfo.app == "Spotify" ? "music.note.list" : "music.note")
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(mediaInfo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(mediaInfo.artist)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                Button(action: onPlayPause) {
                    Image(systemName: mediaInfo.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

// Custom button style for scaling effect and hover effect
struct HoverableButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            label()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.10) : Color.primary.opacity(0.04))
                )
                .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.03 : 1.0))
                .opacity(isPressed ? 0.85 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isPressed)
                .animation(.easeOut(duration: 0.18), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .pressAction {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

// Helper for press action
struct PressActionModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() })
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressActionModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Quick Files Popover
struct QuickFilesPopover: View {
    @Binding var quickFiles: [URL]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Quick Files")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .padding(.horizontal, 12)
            Divider()
            if quickFiles.isEmpty {
                Text("Drop files here for quick access.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(16)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(quickFiles, id: \.self) { url in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.accentColor)
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    if let idx = quickFiles.firstIndex(of: url) {
                                        quickFiles.remove(at: idx)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                NSWorkspace.shared.open(url)
                            }
                            .onDrag {
                                NSItemProvider(object: url as NSURL)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            DispatchQueue.main.async {
                                if !quickFiles.contains(url) {
                                    quickFiles.append(url)
                                }
                            }
                        } else if let url = item as? URL {
                            DispatchQueue.main.async {
                                if !quickFiles.contains(url) {
                                    quickFiles.append(url)
                                }
                            }
                        }
                    }
                }
            }
            return true
        }
    }
}

// MARK: - UserDefaults helper for quickFiles
extension UserDefaults {
    private static let quickFilesKey = "quickFilesKey"
    var quickFiles: [URL] {
        get {
            guard let data = data(forKey: Self.quickFilesKey),
                  let strings = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return strings.compactMap { URL(string: $0) }
        }
        set {
            let strings = newValue.map { $0.absoluteString }
            if let data = try? JSONEncoder().encode(strings) {
                set(data, forKey: Self.quickFilesKey)
            }
        }
    }
}

// Helper for debouncing quick action animation
extension DynamicIslandView {
    private func debounceQuickActionAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            isAnimatingQuickAction = false
        }
    }
    private func startCarouselCooldown() {
        isCarouselCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            isCarouselCooldown = false
        }
    }
}

// Helper for carousel arrow hover
extension DynamicIslandView {
    private func handleCarouselArrowHover(hovering: Bool) {
        if hovering {
            carouselArrowHideTask?.cancel()
            showCarouselArrows = true
        } else {
            let task = DispatchWorkItem {
                showCarouselArrows = false
            }
            carouselArrowHideTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
        }
    }
}

// Add MainViewType enum
enum MainViewType {
    case systemMonitor
    case quickFiles
}

// MARK: - System Stats Helper
class SystemStatsHelper {
    // CPU
    private var prevCpuTicks: [[Int32]]? = nil
    private var numCpus: UInt32 = 0
    private let cpuLock = NSLock()

    init() {
        var ncpu: UInt32 = 0
        var size = MemoryLayout<UInt32>.size
        sysctlbyname("hw.ncpu", &ncpu, &size, nil, 0)
        numCpus = ncpu
    }

    func getPerCoreCPUUsage() -> [Double] {
        var coreUsages: [Double] = []
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo)
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return Array(repeating: 0, count: Int(numCpus)) }
        var newTicks: [[Int32]] = []
        for i in 0..<Int(numCPUsU) {
            let offset = i * Int(CPU_STATE_MAX)
            let user = cpuInfo[offset + Int(CPU_STATE_USER)]
            let system = cpuInfo[offset + Int(CPU_STATE_SYSTEM)]
            let nice = cpuInfo[offset + Int(CPU_STATE_NICE)]
            let idle = cpuInfo[offset + Int(CPU_STATE_IDLE)]
            newTicks.append([user, system, nice, idle])
        }
        if let prev = prevCpuTicks, prev.count == newTicks.count {
            for i in 0..<newTicks.count {
                let user = Double(newTicks[i][0] - prev[i][0])
                let system = Double(newTicks[i][1] - prev[i][1])
                let nice = Double(newTicks[i][2] - prev[i][2])
                let idle = Double(newTicks[i][3] - prev[i][3])
                let total = user + system + nice + idle
                let usage = (total > 0) ? ((user + system + nice) / total) * 100.0 : 0.0
                coreUsages.append(usage)
            }
        } else {
            // First call, can't calculate delta
            coreUsages = Array(repeating: 0, count: newTicks.count)
        }
        prevCpuTicks = newTicks
        return coreUsages
    }

    // RAM
    func getRAMUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let used = Double(stats.active_count + stats.inactive_count + stats.wire_count)
        let total = Double(stats.active_count + stats.inactive_count + stats.wire_count + stats.free_count)
        return (total > 0) ? (used / total) * 100.0 : 0.0
    }

    // SSD
    func getSSDUsage() -> Double {
        let fileURL = URL(fileURLWithPath: "/")
        if let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]),
           let available = values.volumeAvailableCapacity,
           let total = values.volumeTotalCapacity {
            let used = Double(Int64(total) - Int64(available))
            return (Double(total) > 0) ? (used / Double(Int64(total))) * 100.0 : 0.0
        }
        return 0
    }
}

// Add SystemMonitorView at the bottom
struct SystemMonitorView: View {
    @State private var cpuCoreUsages: [Double] = Array(repeating: 0, count: 14) // 10 performance + 4 efficiency
    @State private var gpuCoreUsages: [Double] = Array(repeating: 0, count: 20) // 20 GPU cores
    @State private var ramUsage: Double = 0
    @State private var fanSpeed: Double = 0
    @State private var ssdUsage: Double = 0
    @State private var wattage: Double = 0
    @State private var timer: Timer? = nil
    private let statsHelper = SystemStatsHelper()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("System Usage")
                .font(.headline)
                .padding(.bottom, 2)
            // CPU Usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CPU")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", cpuCoreUsages.reduce(0, +) / Double(cpuCoreUsages.count)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                BarChart(usages: cpuCoreUsages, color: .accentColor, coreTypeProvider: { idx in idx < 10 ? .performance : .efficiency })
                    .frame(height: 40)
            }
            // GPU Usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("GPU")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", gpuCoreUsages.reduce(0, +) / Double(gpuCoreUsages.count)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                BarChart(usages: gpuCoreUsages, color: .purple, coreTypeProvider: { _ in .gpu })
                    .frame(height: 40)
            }
            // RAM Usage
            HStack {
                Text("RAM")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f%%", ramUsage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            // Fan Speed
            HStack {
                Text("Fans")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.0f RPM", fanSpeed))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            // SSD Usage
            HStack {
                Text("SSD")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f%%", ssdUsage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            // Wattage
            HStack {
                Text("Wattage")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f W", wattage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    private func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Real per-core CPU usage
            let cpuUsages = statsHelper.getPerCoreCPUUsage()
            cpuCoreUsages = cpuUsages.count == 14 ? cpuUsages : Array(cpuUsages.prefix(14)) + Array(repeating: 0, count: max(0, 14 - cpuUsages.count))
            // GPU usage: No public API for per-core, so keep as placeholder
            gpuCoreUsages = (0..<gpuCoreUsages.count).map { _ in Double.random(in: 5...100) } // Placeholder
            ramUsage = statsHelper.getRAMUsage()
            fanSpeed = Double.random(in: 1200...3500) // Placeholder
            ssdUsage = statsHelper.getSSDUsage()
            wattage = Double.random(in: 10...60) // Placeholder
        }
    }
}

// Bar chart for per-core usage
struct BarChart: View {
    let usages: [Double] // 0...100
    let color: Color
    var coreTypeProvider: ((Int) -> CoreType)? = nil // Optional closure to determine core type
    enum CoreType { case performance, efficiency, gpu }
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let barCount = usages.count
            let barWidth = max((geo.size.width - spacing * CGFloat(barCount - 1)) / CGFloat(barCount), 6)
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(usages.indices, id: \ .self) { idx in
                    let usage = usages[idx]
                    let barHeight = geo.size.height
                    let usageHeight = max(barHeight * CGFloat(usage / 100), 4)
                    let coreType = coreTypeProvider?(idx) ?? .gpu
                    let bgColor: Color = {
                        switch coreType {
                        case .performance: return Color.blue.opacity(0.18)
                        case .efficiency: return Color.teal.opacity(0.18)
                        case .gpu: return Color.purple.opacity(0.18)
                        }
                    }()
                    let fgColor: Color = {
                        switch coreType {
                        case .performance: return Color.blue
                        case .efficiency: return Color.teal
                        case .gpu: return Color.purple
                        }
                    }()
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(bgColor)
                            .frame(width: barWidth, height: barHeight)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(fgColor)
                            .frame(width: barWidth, height: usageHeight)
                            .animation(.easeOut(duration: 0.25), value: usage)
                    }
                    .frame(width: barWidth, height: barHeight)
                    .help("\(Int(usage))%")
                }
            }
        }
    }
}

// Add new QuickFilesGallery view:
struct QuickFilesGallery: View {
    @Binding var quickFiles: [URL]
    let columns = [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: 16)]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed header
            VStack(alignment: .leading, spacing: 0) {
                Text("Quick Files Gallery")
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 12)
                Divider()
            }
            .background(Color.primary.opacity(0.03))
            // Scrollable content
            if quickFiles.isEmpty {
                ScrollView {
                    VStack {
                        Text("Drop files here for quick access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(16)
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(quickFiles, id: \.self) { url in
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 6) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .cornerRadius(8)
                                        .shadow(radius: 2, y: 1)
                                    Text(url.lastPathComponent)
                                        .font(.caption2)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 80)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    NSWorkspace.shared.open(url)
                                }
                                .onDrag {
                                    NSItemProvider(object: url as NSURL)
                                }
                                Button(action: {
                                    if let idx = quickFiles.firstIndex(of: url) {
                                        quickFiles.remove(at: idx)
                                    }
                                }) {
                                    Image(systemName: "trash.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white.opacity(0.7))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            DispatchQueue.main.async {
                                if !quickFiles.contains(url) {
                                    quickFiles.append(url)
                                }
                            }
                        } else if let url = item as? URL {
                            DispatchQueue.main.async {
                                if !quickFiles.contains(url) {
                                    quickFiles.append(url)
                                }
                            }
                        }
                    }
                }
            }
            return true
        }
    }
}
