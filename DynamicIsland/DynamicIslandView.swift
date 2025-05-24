import SwiftUI
import AppKit

struct DynamicIslandView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showActionsPopover = false
    @State private var showFilesPopover = false
    @State private var mediaInfo: MediaInfo? = nil
    @State private var quickFiles: [URL] = UserDefaults.standard.quickFiles
    
    var body: some View {
        ZStack {
            // Main island container with enhanced blur and shadow
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.18))
                        .blur(radius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
                )
                .frame(width: 340, height: 240)
                .shadow(color: Color.black.opacity(0.25), radius: 32, x: 0, y: 16)
                .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 2)
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "macbook")
                            .font(.title2)
                            .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dynamic Island")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("macOS Enhanced")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    // Folder icon for quick file access
                    Button(action: { showFilesPopover.toggle() }) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color.yellow)
                            .background(Color.clear)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .popover(isPresented: $showFilesPopover, arrowEdge: .top) {
                        QuickFilesPopover(quickFiles: $quickFiles)
                            .frame(width: 220, height: 220)
                    }
                    .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                        handleFileDrop(providers: providers)
                    }
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
                .padding(.top, 22)
                .padding(.bottom, 8)
                
                // Separator
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                // Media Control Section
                if let mediaInfo = mediaInfo {
                    MediaControlView(
                        mediaInfo: mediaInfo,
                        onPlayPause: { handleMediaControl(.playPause) },
                        onNext: { handleMediaControl(.next) },
                        onPrevious: { handleMediaControl(.previous) },
                        onStop: { handleMediaControl(.stop) }
                    )
                    .padding(.bottom, 8)
                }
                
                // Main content can go here (empty for now)
                Spacer()
            }
        }
        .frame(width: 340, height: 240)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: UUID())
        .onAppear {
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
        // Allow dropping files anywhere on the window
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            handleFileDrop(providers: providers)
        }
        // Save quickFiles to UserDefaults whenever it changes
        .onChange(of: quickFiles) { _, newValue in
            UserDefaults.standard.quickFiles = newValue
        }
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
                            Button(action: {
                                NSWorkspace.shared.open(url)
                            }) {
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
                            }
                            .buttonStyle(PlainButtonStyle())
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
