import SwiftUI
import AppKit
import Foundation
import Combine

struct DynamicIslandView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showActionsPopover = false
    @State private var showFilesPopover = false
    @State private var mediaInfo: MediaInfo? = nil
    @State private var quickFiles: [URL] = UserDefaults.standard.quickFiles
    @State private var quickApps: [URL] = UserDefaults.standard.quickApps
    @State private var clipboardItems: [ClipboardItem] = []
    @State private var isDropTargeted = false
    @State private var showDropPulse = false
    @State private var selectedView: MainViewType = .clipboard
    @State private var isPopped: Bool = false
    @StateObject private var clipboardWatcher = GlobalClipboardWatcher.shared
    var body: some View {
        ZStack {
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
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(isDropTargeted ? Color.accentColor.opacity(0.7) : Color.clear, lineWidth: isDropTargeted ? 4 : 0)
                .shadow(color: isDropTargeted ? Color.accentColor.opacity(0.3) : .clear, radius: 16, x: 0, y: 4)
                .scaleEffect(showDropPulse ? 1.08 : 1.0)
                .opacity(isDropTargeted || showDropPulse ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDropTargeted)
                .animation(.easeOut(duration: 0.2), value: showDropPulse)
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Button(action: {
                            if let url = URL(string: "x-apple-weather://"), NSWorkspace.shared.open(url) {
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
                        Button(action: { showActionsPopover.toggle() }) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(Color.accentColor)
                                .background(Color.clear)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                        .popover(isPresented: $showActionsPopover, arrowEdge: .top) {
                            QuickFilesPopover(quickFiles: $quickFiles)
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
                    .padding(.top, 0)
                    .padding(.bottom, 2)
                    HStack(spacing: 16) {
                        Button(action: { selectedView = .clipboard }) {
                            Image(systemName: "doc.on.clipboard.fill")
                                .font(.title3)
                                .foregroundColor(selectedView == .clipboard ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                        Button(action: { selectedView = .quickApp }) {
                            Image(systemName: "app.fill")
                                .font(.title3)
                                .foregroundColor(selectedView == .quickApp ? .purple : .secondary)
                        }
                        .buttonStyle(.plain)
                        Button(action: { selectedView = .quickFiles }) {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(selectedView == .quickFiles ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                        Button(action: { selectedView = .systemMonitor }) {
                            Image(systemName: "gauge.high")
                                .font(.title3)
                                .foregroundColor(selectedView == .systemMonitor ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 0)
                    HStack {
                        Text(selectedView == .clipboard ? "Clipboard" : selectedView == .quickApp ? "Quick App" : selectedView == .systemMonitor ? "System Usage" : "Quick Files Gallery")
                            .font(.headline)
                            .padding(.leading, 16)
                            .padding(.top, 0)
                            .padding(.bottom, 2)
                        Spacer()
                    }
                }
                .frame(height: 110)
                .background(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            NotificationCenter.default.post(name: NSNotification.Name("DynamicIslandDragWindow"), object: value)
                        }
                )
                Group {
                    switch selectedView {
                    case .clipboard:
                        ClipboardManagerGallery(clipboardItems: $clipboardWatcher.items)
                    case .quickApp:
                        QuickAppGallery(quickApps: $quickApps)
                            .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                                handleAppDrop(providers: providers)
                            }
                    case .quickFiles:
                        QuickFilesGallery(quickFiles: $quickFiles)
                    case .systemMonitor:
                        SystemMonitorView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
            }
        }
        .frame(width: 340, height: 380)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                isPopped = true
            }
            quickFiles = UserDefaults.standard.quickFiles
            quickApps = UserDefaults.standard.quickApps
            clipboardWatcher.start()
        }
        .onDisappear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                isPopped = false
            }
            clipboardWatcher.stop()
        }
        .onChange(of: quickFiles) { _, newValue in
            UserDefaults.standard.quickFiles = newValue
        }
        .onChange(of: quickApps) { _, newValue in
            UserDefaults.standard.quickApps = newValue
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
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil), url.pathExtension == "app" {
                        // ignore .app here, only for quickApps
                        return
                    } else if let url = item as? URL, url.pathExtension == "app" {
                        // ignore .app here, only for quickApps
                        return
                    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
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
}

enum MainViewType {
    case clipboard
    case quickApp
    case quickFiles
    case systemMonitor
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

