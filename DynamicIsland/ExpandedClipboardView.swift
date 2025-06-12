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
            GeometryReader { geometry in
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
                
                    // Clear all button - adaptive based on width
                if !clipboardWatcher.items.isEmpty {
                    Button(action: {
                        clipboardWatcher.clearAll()
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                                
                                // Only show text if there's enough width
                                if geometry.size.width > 400 {
                            Text("Clear All")
                                .font(DesignSystem.Typography.captionMedium)
                                }
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
            }
            .frame(height: 60) // Fixed height for title area
            
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
        .padding(.top, 40) // Space for window controls within glass
    }
    
    private var categoryFilter: some View {
        GeometryReader { geometry in
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
                    
                    // Show text only if there's enough width (roughly 320px minimum for all text)
                    let showText = geometry.size.width > 320
                
                Button(action: {
                    withAnimation(DesignSystem.Animation.gentle) {
                        selectedFilter = filter
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: filter.icon)
                                .font(.system(size: 14, weight: .medium))
                            
                            if showText {
                        Text(filter.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                        Text("(\(count))")
                                    .font(.system(size: 13))
                            } else if selectedFilter == filter {
                                // Only show count for selected filter when in icon mode
                                Text("\(count)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                    }
                    .foregroundColor(selectedFilter == filter ? .white : filter.color)
                        .padding(.horizontal, showText ? DesignSystem.Spacing.lg : DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(selectedFilter == filter ? filter.color : filter.color.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        }
        .frame(height: 44) // Fixed height for the filter bar
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
            // Use cached data for immediate clipboard operation
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
            Task {
                // Try to get the full image first for best quality
                if let fullImage = await item.fullImage() {
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + ".png")
                    
                    // Convert NSImage to PNG data
                    if let tiffData = fullImage.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmap.representation(using: .png, properties: [:]) {
                        do {
                            try pngData.write(to: tempURL)
                            await MainActor.run {
                                NSWorkspace.shared.open(tempURL)
                            }
                        } catch {
                            print("Failed to write full image to temp file: \(error)")
                        }
                    }
                }
                // Fallback to cached data
                else if let data = item.imageData {
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + ".png")
                    do {
                        try data.write(to: tempURL)
                        await MainActor.run {
                            NSWorkspace.shared.open(tempURL)
                        }
                    } catch {
                        print("Failed to write cached image to temp file: \(error)")
                    }
                }
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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with type icon and actions
            HStack {
                // Type indicator
                Image(systemName: typeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(typeColor)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                // Pin indicator
                if item.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.warning)
                }
                
                // Action buttons (shown on hover)
                if isHovered {
                    HStack(spacing: 6) {
                        ClipboardActionButton(icon: "pin\(item.pinned ? ".slash" : "")", action: onPin)
                        ClipboardActionButton(icon: "doc.on.doc", action: onCopy)
                        if item.type == .file || item.type == .image {
                            ClipboardActionButton(icon: "arrow.up.right.square", action: onOpen)
                        }
                        ClipboardActionButton(icon: "trash", color: DesignSystem.Colors.error, action: onRemove)
                    }
                }
            }
            
            // Content preview with consistent height
            VStack(alignment: .leading, spacing: 0) {
            contentPreview
                Spacer(minLength: 0)
            }
            .frame(height: 100) // Fixed height for consistency
            
            // Footer with timestamp
            HStack {
                Text(timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if justCopied {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Copied")
                            .font(.system(size: 12))
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
                ScrollView {
                Text(item.content ?? "")
                        .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(6)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
            case .image:
                HStack {
                    Spacer()
                    AsyncClipboardImageExpanded(item: item)
                        .frame(maxHeight: 90)
                        .cornerRadius(DesignSystem.BorderRadius.md)
                    Spacer()
                }
                
            case .file:
                VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "doc.fill")
                            .font(.system(size: 28, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.files)
                    
                        VStack(alignment: .leading, spacing: 4) {
                        Text(item.fileURL?.lastPathComponent ?? "Unknown File")
                                .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(2)
                        
                        if let url = item.fileURL {
                            Text(url.deletingLastPathComponent().path)
                                    .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
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
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Async Clipboard Image for Expanded View

struct AsyncClipboardImageExpanded: View {
    let item: ClipboardItem
    @State private var image: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                // Loading placeholder
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(height: 60)
            } else {
                // Error placeholder
                Image(systemName: "photo")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(height: 60)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // First try to load full image for expanded view
        if let fullImage = await item.fullImage() {
            await MainActor.run {
                self.image = fullImage
                self.isLoading = false
            }
        }
        // Fallback to thumbnail
        else if let thumbnail = await item.thumbnailImage() {
            await MainActor.run {
                self.image = thumbnail
                self.isLoading = false
            }
        }
        // Last resort - legacy sync method
        else if let data = item.imageData, let fallbackImage = NSImage(data: data) {
            await MainActor.run {
                self.image = fallbackImage
                self.isLoading = false
            }
        }
        // No image available
        else {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
} 