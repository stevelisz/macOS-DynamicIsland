import SwiftUI
import AppKit

struct ExpandedClipboardView: View {
    @StateObject private var clipboardWatcher = GlobalClipboardWatcher.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: ClipboardFilter = .all
    @State private var justCopiedId: UUID? = nil
    @State private var hoveredItemId: UUID? = nil
    
    enum ClipboardFilter: String, CaseIterable {
        case all = "All"
        case text = "Text"
        case image = "Images"
        case file = "Files"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.3x3"
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
    
    private var filteredItems: [ClipboardItem] {
        let filtered = clipboardWatcher.items.filter { item in
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
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and filters
            headerSection
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Main content area
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                clipboardGrid
            }
        }
        .background(Color.clear)
        .onAppear {
            clipboardWatcher.start()
        }
        .onDisappear {
            clipboardWatcher.stop()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Title and stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clipboard Manager")
                        .font(DesignSystem.Typography.headline1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(filteredItems.count) items")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Clear all button
                if !clipboardWatcher.items.isEmpty {
                    Button(action: {
                        clipboardWatcher.clearAll()
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                            Text("Clear All")
                                .font(DesignSystem.Typography.captionMedium)
                        }
                        .foregroundColor(DesignSystem.Colors.error)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .fill(DesignSystem.Colors.error.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Search bar
            HStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    TextField("Search clipboard items...", text: $searchText)
                        .font(DesignSystem.Typography.body)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                )
                
                // Category filter
                categoryFilter
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xxl)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    private var categoryFilter: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                let count = clipboardWatcher.items.filter { item in
                    switch filter {
                    case .all: return true
                    case .text: return item.type == .text
                    case .image: return item.type == .image
                    case .file: return item.type == .file
                    }
                }.count
                
                Button(action: {
                    withAnimation(DesignSystem.Animation.gentle) {
                        selectedFilter = filter
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: filter.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(filter.rawValue)
                            .font(DesignSystem.Typography.captionMedium)
                        Text("(\(count))")
                            .font(DesignSystem.Typography.micro)
                    }
                    .foregroundColor(selectedFilter == filter ? .white : filter.color)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(selectedFilter == filter ? filter.color : filter.color.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Clipboard Grid
    
    private var clipboardGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredItems, id: \.id) { item in
                    ExpandedClipboardCard(
                        item: item,
                        isHovered: hoveredItemId == item.id,
                        justCopied: justCopiedId == item.id,
                        onCopy: { copyToClipboard(item) },
                        onPin: { togglePin(item) },
                        onRemove: { removeItem(item) },
                        onOpen: { openItem(item) }
                    )
                    .onHover { isHovered in
                        hoveredItemId = isHovered ? item.id : nil
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            .padding(.vertical, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: selectedFilter == .all ? "doc.on.clipboard" : selectedFilter.icon)
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(selectedFilter == .all ? "No Clipboard Items" : "No \(selectedFilter.rawValue)")
                        .font(DesignSystem.Typography.headline2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(selectedFilter == .all ? 
                         "Copy something to get started" : 
                         "Copy \(selectedFilter.rawValue.lowercased()) to see them here")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func copyToClipboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        
        switch item.type {
        case .text:
            if let text = item.content { 
                pb.setString(text, forType: .string) 
            }
        case .image:
            if let data = item.imageData, let img = NSImage(data: data) {
                pb.writeObjects([img])
            }
        case .file:
            item.accessFileForPasteboard { url in
                pb.writeObjects([url as NSURL])
                pb.addTypes([.fileURL], owner: nil)
                pb.setString(url.absoluteString, forType: .fileURL)
            }
        }
        
        // Show feedback
        justCopiedId = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if justCopiedId == item.id { 
                justCopiedId = nil 
            }
        }
    }
    
    private func togglePin(_ item: ClipboardItem) {
        if item.pinned {
            clipboardWatcher.unpin(item)
        } else {
            clipboardWatcher.pin(item)
        }
    }
    
    private func removeItem(_ item: ClipboardItem) {
        clipboardWatcher.remove(item)
    }
    
    private func openItem(_ item: ClipboardItem) {
        switch item.type {
        case .file:
            _ = item.accessFile { url in
                NSWorkspace.shared.open(url)
            }
        case .image:
            if let data = item.imageData {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
                try? data.write(to: tmp)
                NSWorkspace.shared.open(tmp)
            }
        default: 
            break
        }
    }
}

// MARK: - Expanded Clipboard Card

struct ExpandedClipboardCard: View {
    let item: ClipboardItem
    let isHovered: Bool
    let justCopied: Bool
    let onCopy: () -> Void
    let onPin: () -> Void
    let onRemove: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header with type icon and actions
            HStack {
                // Type indicator
                Image(systemName: typeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(typeColor)
                    .frame(width: 20, height: 20)
                
                Spacer()
                
                // Pin indicator
                if item.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.warning)
                }
                
                // Action buttons (shown on hover)
                if isHovered {
                    HStack(spacing: 4) {
                        ClipboardActionButton(icon: "pin\(item.pinned ? ".slash" : "")", action: onPin)
                        ClipboardActionButton(icon: "doc.on.doc", action: onCopy)
                        if item.type == .file || item.type == .image {
                            ClipboardActionButton(icon: "arrow.up.right.square", action: onOpen)
                        }
                        ClipboardActionButton(icon: "trash", color: DesignSystem.Colors.error, action: onRemove)
                    }
                }
            }
            
            // Content preview
            contentPreview
            
            // Footer with timestamp
            HStack {
                Text(timeAgo)
                    .font(DesignSystem.Typography.micro)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if justCopied {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Copied")
                            .font(DesignSystem.Typography.micro)
                    }
                    .foregroundColor(DesignSystem.Colors.success)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                        .stroke(isHovered ? DesignSystem.Colors.borderHover : DesignSystem.Colors.border, lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: DesignSystem.Shadows.md.color,
            radius: isHovered ? DesignSystem.Shadows.lg.radius : DesignSystem.Shadows.md.radius,
            x: DesignSystem.Shadows.md.x,
            y: DesignSystem.Shadows.md.y
        )
        .animation(DesignSystem.Animation.gentle, value: isHovered)
        .animation(DesignSystem.Animation.gentle, value: justCopied)
    }
    
    private var contentPreview: some View {
        Group {
            switch item.type {
            case .text:
                Text(item.content ?? "")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            case .image:
                if let data = item.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 120)
                        .cornerRadius(DesignSystem.BorderRadius.md)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(height: 80)
                }
                
            case .file:
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.files)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.fileURL?.lastPathComponent ?? "Unknown File")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(2)
                        
                        if let url = item.fileURL {
                            Text(url.deletingLastPathComponent().path)
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.date, relativeTo: Date())
    }
}

// MARK: - Action Button

struct ClipboardActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, color: Color = DesignSystem.Colors.textSecondary, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
} 