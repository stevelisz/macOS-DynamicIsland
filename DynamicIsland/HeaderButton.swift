import SwiftUI

struct HeaderButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle (subtle, appears on hover) - constrained size
                Circle()
                    .fill(isHovered ? DesignSystem.Colors.surface : Color.clear)
                    .frame(width: 24, height: 24)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isHovered ? DesignSystem.Colors.textPrimary : color)
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.Animation.gentle, value: isHovered)
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 28)
        .clipped()
        .onHover { isHovered = $0 }
    }
}

struct HeaderMenuButton<MenuContent: View>: View {
    let icon: String
    let color: Color
    let menuContent: MenuContent
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(icon: String, color: Color, @ViewBuilder menu: () -> MenuContent) {
        self.icon = icon
        self.color = color
        self.menuContent = menu()
    }
    
    var body: some View {
        Menu {
            menuContent
        } label: {
            ZStack {
                // Background circle (subtle, appears on hover) - constrained size
                Circle()
                    .fill(isHovered ? DesignSystem.Colors.surface : Color.clear)
                    .frame(width: 24, height: 24)
                
                // Icon - only the 3 dots, no dropdown arrow
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isHovered ? DesignSystem.Colors.textPrimary : color)
            }
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
            .animation(DesignSystem.Animation.gentle, value: isHovered)
            .animation(DesignSystem.Animation.gentle, value: isPressed)
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .frame(width: 28, height: 28)
        .clipped()
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
} 