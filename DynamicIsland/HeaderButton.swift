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