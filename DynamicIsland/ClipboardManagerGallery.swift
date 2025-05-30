import SwiftUI
import AppKit
import Foundation

// ClipboardItem and ClipboardItemType are now defined in DynamicIslandView.swift (or should be in ClipboardItem.swift)

struct ClipboardManagerGallery: View {
    @Binding var clipboardItems: [ClipboardItem]
    @State private var searchText: String = ""
    @State private var justCopiedId: UUID? = nil // Track which card was just copied
    @State private var hoveredItemId: UUID? = nil
    @State private var selectedFilter: ClipboardFilter = .all
    
    enum ClipboardFilter: String, CaseIterable {
        case all = "All"
        case text = "Text"
        case image = "Images"
        case file = "Files"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .text: return "doc.text"
            case .image: return "photo"
            case .file: return "doc"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return DesignSystem.Colors.textSecondary
            case .text: return DesignSystem.Colors.clipboard
            case .image: return DesignSystem.Colors.apps
            case .file: return DesignSystem.Colors.files
            }
        }
    }
    
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
            // Use specialized pasteboard method that maintains security-scoped access longer
            item.accessFileForPasteboard { url in
                // Write the file URL to pasteboard with multiple formats for compatibility
                pb.writeObjects([url as NSURL])
                
                // Add additional pasteboard types for broader app compatibility
                pb.addTypes([.fileURL], owner: nil)
                pb.setString(url.absoluteString, forType: .fileURL)
                
                print("Copied file to pasteboard: \(url.lastPathComponent)")
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
            _ = item.accessFile { url in
                NSWorkspace.shared.open(url)
            }
        case .image:
            if let data = item.imageData, let _ = NSImage(data: data) {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
                try? data.write(to: tmp)
                NSWorkspace.shared.open(tmp)
            }
        default: break
        }
    }
    var filteredItems: [ClipboardItem] {
        let filtered = clipboardItems.filter { item in
            // Apply category filter
            let matchesCategory: Bool
            switch selectedFilter {
            case .all:
                matchesCategory = true
            case .text:
                matchesCategory = item.type == .text
            case .image:
                matchesCategory = item.type == .image
            case .file:
                matchesCategory = item.type == .file
            }
            
            // Apply search filter
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                switch item.type {
                case .text: 
                    matchesSearch = item.content?.localizedCaseInsensitiveContains(searchText) ?? false
                case .file: 
                    matchesSearch = item.fileURL?.lastPathComponent.localizedCaseInsensitiveContains(searchText) ?? false
                case .image: 
                    matchesSearch = false // Images don't have searchable text
                }
            }
            
            return matchesCategory && matchesSearch
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
            
            // Category Filter
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: clipboardItems.filter { item in
                            switch filter {
                            case .all: return true
                            case .text: return item.type == .text
                            case .image: return item.type == .image
                            case .file: return item.type == .file
                            }
                        }.count
                    ) {
                        withAnimation(DesignSystem.Animation.gentle) {
                            selectedFilter = filter
                        }
                    }
                }
                
                Spacer()
            }
            
            if filteredItems.isEmpty {
                // Empty state
                VStack(spacing: DesignSystem.Spacing.md) {
                    Spacer()
                    
                    Image(systemName: selectedFilter == .all ? "doc.on.clipboard" : selectedFilter.icon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text(emptyStateTitle)
                        .font(DesignSystem.Typography.headline3)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(emptyStateSubtitle)
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
    
    // MARK: - Computed Properties
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return clipboardItems.isEmpty ? "Clipboard is empty" : "No items found"
        case .text:
            return "No text items"
        case .image:
            return "No images"
        case .file:
            return "No files"
        }
    }
    
    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .all:
            return clipboardItems.isEmpty ? "Copy something to see it here" : "Try adjusting your search or filter"
        case .text:
            return "Copy some text to see it here"
        case .image:
            return "Copy images to see them here"
        case .file:
            return "Copy files to see them here"
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

// MARK: - Filter Chip Component
struct FilterChip: View {
    let filter: ClipboardManagerGallery.ClipboardFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Text(filter.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(textColor)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(badgeTextColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(badgeBackground)
                        .cornerRadius(DesignSystem.BorderRadius.round)
                        .fixedSize()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 4)
            .frame(minWidth: 50)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.BorderRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .stroke(borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.gentle) {
                isHovered = hovering
            }
        }
        .animation(DesignSystem.Animation.gentle, value: isSelected)
        .animation(DesignSystem.Animation.gentle, value: isHovered)
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        if isSelected {
            return filter.color.opacity(0.15)
        } else if isHovered {
            return DesignSystem.Colors.surface.opacity(0.6)
        } else {
            return DesignSystem.Colors.surface.opacity(0.3)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return filter.color.opacity(0.4)
        } else {
            return DesignSystem.Colors.border.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return filter.color
        } else {
            return DesignSystem.Colors.textSecondary
        }
    }
    
    private var badgeBackground: Color {
        if isSelected {
            return filter.color.opacity(0.2)
        } else {
            return DesignSystem.Colors.border.opacity(0.2)
        }
    }
    
    private var badgeTextColor: Color {
        if isSelected {
            return filter.color
        } else {
            return DesignSystem.Colors.textTertiary
        }
    }
} 