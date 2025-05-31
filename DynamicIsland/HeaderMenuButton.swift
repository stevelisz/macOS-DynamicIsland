import SwiftUI

struct HeaderMenuButton<MenuContent: View>: View {
    let icon: String
    let color: Color
    let menuContent: () -> MenuContent
    @State private var isHovered = false
    
    init(
        icon: String,
        color: Color,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.icon = icon
        self.color = color
        self.menuContent = menuContent
    }
    
    var body: some View {
        Menu {
            menuContent()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isHovered ? color.opacity(0.8) : color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isHovered ? DesignSystem.Colors.surface : Color.clear)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(DesignSystem.Animation.gentle, value: isHovered)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .onHover { isHovered = $0 }
    }
} 