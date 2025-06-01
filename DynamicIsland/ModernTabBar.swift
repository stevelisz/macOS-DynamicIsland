import SwiftUI

struct ModernTabBar: View {
    @Binding var selectedView: MainViewType
    @Binding var enabledTabs: Set<MainViewType>
    @State private var hoveredTab: MainViewType? = nil
    @State private var draggedTab: MainViewType? = nil
    @State private var tabOrder: [MainViewType] = UserDefaults.standard.tabOrder
    
    private let tabData: [MainViewType: (String, String, Color)] = [
        .clipboard: ("doc.on.clipboard.fill", "Clipboard", DesignSystem.Colors.clipboard),
        .quickApp: ("app.fill", "Apps", DesignSystem.Colors.apps),
        .systemMonitor: ("gauge.high", "System", DesignSystem.Colors.system),
        .weather: ("cloud.sun.fill", "Weather", DesignSystem.Colors.weather),
        .timer: ("timer", "Timer", DesignSystem.Colors.timer),
        .unitConverter: ("arrow.triangle.2.circlepath", "Converter", DesignSystem.Colors.files),
        .developerTools: ("hammer.fill", "Dev Tools", DesignSystem.Colors.developer),
        .aiAssistant: ("brain.head.profile", "AI Assistant", DesignSystem.Colors.ai)
    ]
    
    // Get enabled tabs in the current order
    private var orderedEnabledTabs: [MainViewType] {
        return tabOrder.filter { enabledTabs.contains($0) }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(Array(orderedEnabledTabs.enumerated()), id: \.element) { index, tabType in
                    if let tabInfo = tabData[tabType] {
                        DraggableTabButton(
                            type: tabType,
                            icon: tabInfo.0,
                            title: tabInfo.1,
                            color: tabInfo.2,
                            isSelected: selectedView == tabType,
                            isHovered: hoveredTab == tabType,
                            isDragged: draggedTab == tabType,
                            index: index,
                            onTap: {
                                withAnimation(DesignSystem.Animation.bounce) {
                                    selectedView = tabType
                                }
                            },
                            onDrop: { droppedTab in
                                moveTab(from: droppedTab, to: tabType)
                            }
                        )
                        .onHover { isHovered in
                            withAnimation(DesignSystem.Animation.gentle) {
                                hoveredTab = isHovered ? tabType : nil
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
        .scrollDisabled(orderedEnabledTabs.count <= 3)
        .animation(DesignSystem.Animation.smooth, value: enabledTabs)
        .animation(DesignSystem.Animation.smooth, value: tabOrder)
        .onAppear {
            tabOrder = UserDefaults.standard.tabOrder
        }
        .onChange(of: enabledTabs) { _, _ in
            // Refresh tab order when enabled tabs change
            tabOrder = UserDefaults.standard.tabOrder
        }
    }
    
    private func moveTab(from source: MainViewType, to target: MainViewType) {
        guard let sourceIndex = tabOrder.firstIndex(of: source),
              let targetIndex = tabOrder.firstIndex(of: target) else { return }
        
        // Update local state immediately
        let movedTab = tabOrder.remove(at: sourceIndex)
        tabOrder.insert(movedTab, at: targetIndex)
        
        // Also persist to UserDefaults
        UserDefaults.standard.tabOrder = tabOrder
    }
}

struct TabButton: View {
    let type: MainViewType
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.2) : (isHovered ? DesignSystem.Colors.surface : Color.clear))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? color : (isHovered ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary))
                }
                .animation(DesignSystem.Animation.gentle, value: isSelected)
                .animation(DesignSystem.Animation.gentle, value: isHovered)
                
                // Text label (only shown when selected or hovered)
                if isSelected || isHovered {
                    Text(title)
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(isSelected ? color : DesignSystem.Colors.textPrimary)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                    .fill(isSelected ? DesignSystem.Colors.surfaceElevated : (isHovered ? DesignSystem.Colors.surface : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered && !isSelected ? 1.05 : 1.0)
            .animation(DesignSystem.Animation.gentle, value: isSelected)
            .animation(DesignSystem.Animation.gentle, value: isHovered)
        }
        .buttonStyle(.plain)
    }
}

struct DraggableTabButton: View {
    let type: MainViewType
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let isHovered: Bool
    let isDragged: Bool
    let index: Int
    let onTap: () -> Void
    let onDrop: (MainViewType) -> Void
    
    @State private var isDropTarget = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Icon with animated background
            ZStack {
                Circle()
                    .fill(isSelected ? color.opacity(0.2) : (isHovered ? DesignSystem.Colors.surface : Color.clear))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? color : (isHovered ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary))
            }
            .animation(DesignSystem.Animation.gentle, value: isSelected)
            .animation(DesignSystem.Animation.gentle, value: isHovered)
            
            // Text label (only shown when selected or hovered)
            if isSelected || isHovered {
                Text(title)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(isSelected ? color : DesignSystem.Colors.textPrimary)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                .fill(isSelected ? DesignSystem.Colors.surfaceElevated : (isHovered ? DesignSystem.Colors.surface : Color.clear))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                        .stroke(
                            isDropTarget ? DesignSystem.Colors.primary.opacity(0.5) : 
                            (isSelected ? color.opacity(0.3) : Color.clear), 
                            lineWidth: isDropTarget ? 2 : 1
                        )
                )
        )
        .scaleEffect(isHovered && !isSelected ? 1.05 : 1.0)
        .scaleEffect(isDropTarget ? 1.1 : 1.0)
        .animation(DesignSystem.Animation.gentle, value: isSelected)
        .animation(DesignSystem.Animation.gentle, value: isHovered)
        .animation(DesignSystem.Animation.gentle, value: isDropTarget)
        .onTapGesture {
            onTap()
        }
        .draggable(type) {
            // Drag preview
            DragPreview(
                icon: icon,
                title: title,
                color: color
            )
        }
        .dropDestination(for: MainViewType.self) { droppedTabs, location in
            guard let droppedTab = droppedTabs.first,
                  droppedTab != type else { return false }
            
            onDrop(droppedTab)
            
            return true
        } isTargeted: { isTargeted in
            withAnimation(DesignSystem.Animation.gentle) {
                isDropTarget = isTargeted
            }
        }
    }
}

struct DragPreview: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Icon with animated background
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            .animation(DesignSystem.Animation.gentle, value: color)
            
            // Text label (only shown when selected or hovered)
            Text(title)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(color)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                        .stroke(DesignSystem.Colors.surfaceElevated, lineWidth: 1)
                )
        )
    }
} 