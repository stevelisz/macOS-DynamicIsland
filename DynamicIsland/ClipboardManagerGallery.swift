import SwiftUI
import AppKit
import Foundation

// ClipboardItem and ClipboardItemType are now defined in DynamicIslandView.swift (or should be in ClipboardItem.swift)

struct ClipboardManagerGallery: View {
    @Binding var clipboardItems: [ClipboardItem]
    @State private var searchText: String = ""
    @State private var justCopiedId: UUID? = nil // Track which card was just copied
    private func clearAll() { clipboardItems.removeAll() }
    private func pin(_ item: ClipboardItem) {
        if let idx = clipboardItems.firstIndex(of: item) {
            clipboardItems[idx].pinned = true
        }
    }
    private func unpin(_ item: ClipboardItem) {
        if let idx = clipboardItems.firstIndex(of: item) {
            clipboardItems[idx].pinned = false
        }
    }
    private func copyToClipboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case .text:
            if let text = item.content { pb.setString(text, forType: .string) }
        case .image:
            if let data = item.imageData, let img = NSImage(data: data) {
                pb.writeObjects([img])
            }
        case .file:
            if let url = item.fileURL { pb.writeObjects([url as NSURL]) }
        }
        // Show feedback
        justCopiedId = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if justCopiedId == item.id { justCopiedId = nil }
        }
    }
    private func openItem(_ item: ClipboardItem) {
        switch item.type {
        case .file:
            if let url = item.fileURL { NSWorkspace.shared.open(url) }
        case .image:
            if let data = item.imageData, let img = NSImage(data: data) {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
                try? data.write(to: tmp)
                NSWorkspace.shared.open(tmp)
            }
        default: break
        }
    }
    var filteredItems: [ClipboardItem] {
        let filtered = clipboardItems.filter { item in
            if searchText.isEmpty { return true }
            switch item.type {
            case .text: return item.content?.localizedCaseInsensitiveContains(searchText) ?? false
            case .file: return item.fileURL?.lastPathComponent.localizedCaseInsensitiveContains(searchText) ?? false
            case .image: return false // skip for now
            }
        }
        let pinned = filtered.filter { $0.pinned }
        let unpinned = filtered.filter { !$0.pinned }
        return pinned + unpinned
    }
    let cardWidth: CGFloat = 160
    let cardHeight: CGFloat = 72
    let columns = [GridItem(.flexible())]
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 8)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            if filteredItems.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Clipboard is empty.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(16)
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredItems) { item in
                            ZStack(alignment: .topTrailing) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        if item.pinned {
                                            Image(systemName: "star.fill").foregroundColor(.yellow)
                                        }
                                        Spacer()
                                        if item.type == .text {
                                            Image(systemName: "doc.text")
                                                .font(.title3)
                                                .foregroundColor(.accentColor)
                                        } else if item.type == .image {
                                            Image(systemName: "photo")
                                                .font(.title3)
                                                .foregroundColor(.accentColor)
                                        } else if item.type == .file {
                                            Image(systemName: "doc")
                                                .font(.title3)
                                                .foregroundColor(.accentColor)
                                        }
                                        Text(item.date, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    if item.type == .text, let text = item.content {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            Text(text)
                                                .font(.body)
                                                .lineLimit(2)
                                                .truncationMode(.tail)
                                                .padding(.top, 2)
                                        }
                                    } else if item.type == .image, let data = item.imageData, let img = NSImage(data: data) {
                                        Image(nsImage: img)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 40)
                                            .cornerRadius(8)
                                            .shadow(radius: 2, y: 1)
                                    } else if item.type == .file, let url = item.fileURL {
                                        HStack(alignment: .center, spacing: 8) {
                                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 24, height: 24)
                                                .cornerRadius(6)
                                            Text(url.lastPathComponent)
                                                .font(.body)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: 180, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .topLeading)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(12)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    copyToClipboard(item)
                                }
                                .overlay(
                                    Group {
                                        if justCopiedId == item.id {
                                            ZStack {
                                                Color.black.opacity(0.35)
                                                    .cornerRadius(12)
                                                VStack {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 32))
                                                        .foregroundColor(.green)
                                                    Text("Copied!")
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .transition(.opacity)
                                        }
                                    }
                                )
                                .animation(.easeInOut(duration: 0.2), value: justCopiedId)
                                .contextMenu {
                                    if item.pinned {
                                        Button("Unpin") { unpin(item) }
                                    } else {
                                        Button("Pin") { pin(item) }
                                    }
                                    Button("Copy") { copyToClipboard(item) }
                                    if item.type == .file || item.type == .image {
                                        Button("Open") { openItem(item) }
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        if let idx = clipboardItems.firstIndex(of: item) {
                                            clipboardItems.remove(at: idx)
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                }
                .contextMenu {
                    if !clipboardItems.isEmpty {
                        Button(role: .destructive) {
                            clearAll()
                        } label: {
                            Label("Remove All", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
} 