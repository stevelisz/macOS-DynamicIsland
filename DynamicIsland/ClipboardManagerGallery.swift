import SwiftUI
import AppKit
import Foundation

// ClipboardItem and ClipboardItemType are now defined in DynamicIslandView.swift (or should be in ClipboardItem.swift)

struct ClipboardManagerGallery: View {
    @Binding var clipboardItems: [ClipboardItem]
    @State private var searchText: String = ""
    @State private var justCopiedId: UUID? = nil // Track which card was just copied
    @State private var hoveredItemId: UUID? = nil
    
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
    private func remove(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
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
            // Enhanced file copying for cross-app compatibility
            item.accessFile { url in
                // Method 1: Copy file URL with proper pasteboard types
                pb.writeObjects([url as NSURL])
                
                // Method 2: Also add the file URL as a string (for broader compatibility)
                pb.addTypes([.fileURL, .string], owner: nil)
                pb.setString(url.absoluteString, forType: .fileURL)
                pb.setString(url.path, forType: .string)
                
                // Method 3: For maximum compatibility, also try file promise
                if let fileData = try? Data(contentsOf: url) {
                    pb.addTypes([.init("public.file-url")], owner: nil)
                    pb.setData(url.dataRepresentation, forType: .init("public.file-url"))
                }
                
                // Keep security-scoped access alive longer by retaining the URL
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    // Allow time for other apps to access the file
                    _ = url // Keep reference
                }
            }
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
            // Use secure file access to open files
            item.accessFile { url in
                NSWorkspace.shared.open(url)
            }
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
    
    let columns = [GridItem(.flexible())]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Search bar
            HStack {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    TextField("Search clipboard...", text: $searchText)
                        .font(DesignSystem.Typography.body)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.BorderRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                
                Spacer()
                
                // Clear all button
                if !clipboardItems.isEmpty {
                    Button(action: clearAll) {
                        Image(systemName: "trash")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    .buttonStyle_custom(.ghost)
                }
            }
            
            if filteredItems.isEmpty {
                // Empty state
                VStack(spacing: DesignSystem.Spacing.md) {
                    Spacer()
                    
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text("Clipboard is empty")
                        .font(DesignSystem.Typography.headline3)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Copy something to see it here")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Content area - removed internal ScrollView
                LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                    ForEach(filteredItems) { item in
                        ClipboardItemCard(
                            item: item,
                            isHovered: hoveredItemId == item.id,
                            justCopied: justCopiedId == item.id,
                            onCopy: { copyToClipboard(item) },
                            onPin: { item.pinned ? unpin(item) : pin(item) },
                            onOpen: { openItem(item) },
                            onDelete: { remove(item) }
                        )
                        .onHover { isHovered in
                            withAnimation(DesignSystem.Animation.gentle) {
                                hoveredItemId = isHovered ? item.id : nil
                            }
                        }
                        .contextMenu {
                            Button("Copy") { copyToClipboard(item) }
                            Button(item.pinned ? "Unpin" : "Pin") { 
                                item.pinned ? unpin(item) : pin(item) 
                            }
                            if item.type == .file || item.type == .image {
                                Button("Open") { openItem(item) }
                            }
                            Divider()
                            Button("Delete", role: .destructive) { remove(item) }
                        }
                    }
                }
            }
        }
    }
}

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let isHovered: Bool
    let justCopied: Bool
    let onCopy: () -> Void
    let onPin: () -> Void
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header with type icon and timestamp
            HStack(alignment: .top) {
                // Pin indicator
                if item.pinned {
                    Image(systemName: "star.fill")
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.warning)
                }
                
                Spacer()
                
                // Type icon
                Image(systemName: typeIcon)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(typeColor)
                
                // Timestamp
                Text(item.date, style: .time)
                    .font(DesignSystem.Typography.micro)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            // Content
            contentView
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Actions (shown on hover)
            if isHovered || justCopied {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Button(action: onCopy) {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                                .font(DesignSystem.Typography.micro)
                            Text(justCopied ? "Copied!" : "Copy")
                                .font(DesignSystem.Typography.micro)
                        }
                        .foregroundColor(justCopied ? DesignSystem.Colors.success : DesignSystem.Colors.textPrimary)
                    }
                    .buttonStyle_custom(.secondary)
                    
                    Button(action: onPin) {
                        Image(systemName: item.pinned ? "star.slash" : "star")
                            .font(DesignSystem.Typography.micro)
                    }
                    .buttonStyle_custom(.ghost)
                    
                    if item.type == .file || item.type == .image {
                        Button(action: onOpen) {
                            Image(systemName: "arrow.up.right.square")
                                .font(DesignSystem.Typography.micro)
                        }
                        .buttonStyle_custom(.ghost)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    .buttonStyle_custom(.ghost)
                    
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle(isHovered: isHovered)
        .animation(DesignSystem.Animation.gentle, value: isHovered)
        .animation(DesignSystem.Animation.gentle, value: justCopied)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch item.type {
        case .text:
            if let text = item.content {
                Text(text)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
        case .image:
            if let data = item.imageData, let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 60)
                    .cornerRadius(DesignSystem.BorderRadius.sm)
            }
        case .file:
            if let url = item.fileURL {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "doc")
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.files)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text(url.lastPathComponent)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Text(url.deletingLastPathComponent().path)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var typeIcon: String {
        switch item.type {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
    
    private var typeColor: Color {
        switch item.type {
        case .text: return DesignSystem.Colors.clipboard
        case .image: return DesignSystem.Colors.apps
        case .file: return DesignSystem.Colors.files
        }
    }
} 