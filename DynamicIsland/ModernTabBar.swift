import SwiftUI

struct ModernTabBar: View {
    @Binding var selectedView: MainViewType
    @State private var hoveredTab: MainViewType? = nil
    
    private let tabs: [(MainViewType, String, String, Color)] = [
        (.clipboard, "doc.on.clipboard.fill", "Clipboard", DesignSystem.Colors.clipboard),
        (.quickApp, "app.fill", "Apps", DesignSystem.Colors.apps),
        (.systemMonitor, "gauge.high", "System", DesignSystem.Colors.system)
    ]
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                TabButton(
                    type: tab.0,
                    icon: tab.1,
                    title: tab.2,
                    color: tab.3,
                    isSelected: selectedView == tab.0,
                    isHovered: hoveredTab == tab.0
                ) {
                    withAnimation(DesignSystem.Animation.bounce) {
                        selectedView = tab.0
                    }
                }
                .onHover { isHovered in
                    withAnimation(DesignSystem.Animation.gentle) {
                        hoveredTab = isHovered ? tab.0 : nil
                    }
                }
            }
            
            Spacer()
        }
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