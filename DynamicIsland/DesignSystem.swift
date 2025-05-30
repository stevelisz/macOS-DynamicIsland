import SwiftUI

// MARK: - Design System Foundation

struct DesignSystem {
    
    // MARK: - Typography Scale
    struct Typography {
        // Display
        static let display = Font.system(size: 24, weight: .bold, design: .rounded)
        
        // Headlines
        static let headline1 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline2 = Font.system(size: 18, weight: .medium, design: .rounded)
        static let headline3 = Font.system(size: 16, weight: .medium, design: .default)
        
        // Body Text
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
        static let bodySemibold = Font.system(size: 14, weight: .semibold, design: .default)
        
        // Small Text
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let captionSemibold = Font.system(size: 12, weight: .semibold, design: .default)
        
        // Micro Text
        static let micro = Font.system(size: 10, weight: .medium, design: .default)
        static let microSemibold = Font.system(size: 10, weight: .semibold, design: .default)
    }
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Brand Colors
        static let primary = Color(.sRGB, red: 0.0, green: 0.48, blue: 1.0, opacity: 1.0) // iOS Blue
        static let primaryLight = Color(.sRGB, red: 0.2, green: 0.58, blue: 1.0, opacity: 1.0)
        static let primaryDark = Color(.sRGB, red: 0.0, green: 0.38, blue: 0.9, opacity: 1.0)
        
        // Secondary Colors
        static let secondary = Color(.sRGB, red: 0.38, green: 0.38, blue: 0.40, opacity: 1.0)
        static let secondaryLight = Color(.sRGB, red: 0.48, green: 0.48, blue: 0.50, opacity: 1.0)
        static let secondaryDark = Color(.sRGB, red: 0.28, green: 0.28, blue: 0.30, opacity: 1.0)
        
        // Accent Colors
        static let accent = Color(.sRGB, red: 0.35, green: 0.34, blue: 0.84, opacity: 1.0) // Indigo
        static let success = Color(.sRGB, red: 0.0, green: 0.78, blue: 0.35, opacity: 1.0) // Green
        static let warning = Color(.sRGB, red: 1.0, green: 0.58, blue: 0.0, opacity: 1.0) // Orange
        static let error = Color(.sRGB, red: 1.0, green: 0.23, blue: 0.19, opacity: 1.0) // Red
        
        // Semantic Colors
        static let clipboard = Color(.sRGB, red: 0.0, green: 0.78, blue: 0.35, opacity: 1.0) // Green
        static let apps = Color(.sRGB, red: 0.69, green: 0.32, blue: 0.87, opacity: 1.0) // Purple
        static let files = Color(.sRGB, red: 1.0, green: 0.58, blue: 0.0, opacity: 1.0) // Orange
        static let system = Color(.sRGB, red: 0.0, green: 0.48, blue: 1.0, opacity: 1.0) // Blue
        
        // Surface Colors
        static let surface = Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.08)
        static let surfaceElevated = Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.12)
        static let surfaceHover = Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.16)
        
        // Text Colors (Dynamic)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6, opacity: 1.0)
        static let textInverse = Color.white
        
        // Border Colors
        static let border = Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.08)
        static let borderFocus = Color(.sRGB, red: 0.0, green: 0.48, blue: 1.0, opacity: 0.6)
        static let borderHover = Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.16)
    }
    
    // MARK: - Spacing System
    struct Spacing {
        static let micro: CGFloat = 2    // 2pt
        static let xxs: CGFloat = 4      // 4pt
        static let xs: CGFloat = 6       // 6pt
        static let sm: CGFloat = 8       // 8pt
        static let md: CGFloat = 12      // 12pt
        static let lg: CGFloat = 16      // 16pt
        static let xl: CGFloat = 20      // 20pt
        static let xxl: CGFloat = 24     // 24pt
        static let xxxl: CGFloat = 32    // 32pt
        static let huge: CGFloat = 40    // 40pt
        static let massive: CGFloat = 48 // 48pt
    }
    
    // MARK: - Border Radius
    struct BorderRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let round: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let sm = (color: Color.black.opacity(0.08), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.12), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.16), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let xl = (color: Color.black.opacity(0.20), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
    }
    
    // MARK: - Animation Constants
    struct Animation {
        static let fast = 0.15
        static let medium = 0.25
        static let slow = 0.35
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.easeInOut(duration: medium)
        static let gentle = SwiftUI.Animation.easeOut(duration: fast)
    }
}

// MARK: - Custom View Modifiers

struct CardStyle: ViewModifier {
    let isPressed: Bool
    let isHovered: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                            .stroke(isHovered ? DesignSystem.Colors.borderHover : DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: DesignSystem.Shadows.md.color,
                radius: isHovered ? DesignSystem.Shadows.lg.radius : DesignSystem.Shadows.md.radius,
                x: DesignSystem.Shadows.md.x,
                y: DesignSystem.Shadows.md.y
            )
            .animation(DesignSystem.Animation.gentle, value: isPressed)
            .animation(DesignSystem.Animation.gentle, value: isHovered)
    }
}

struct ButtonStyle_Custom: ButtonStyle {
    let variant: ButtonVariant
    @State private var isHovered = false
    
    enum ButtonVariant {
        case primary, secondary, ghost
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.captionSemibold)
            .foregroundColor(textColor)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.BorderRadius.md)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .onHover { isHovered = $0 }
            .animation(DesignSystem.Animation.gentle, value: configuration.isPressed)
            .animation(DesignSystem.Animation.gentle, value: isHovered)
    }
    
    private var backgroundColor: some View {
        Group {
            switch variant {
            case .primary:
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isHovered ? DesignSystem.Colors.primaryLight : DesignSystem.Colors.primary)
            case .secondary:
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isHovered ? DesignSystem.Colors.surfaceHover : DesignSystem.Colors.surface)
            case .ghost:
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isHovered ? DesignSystem.Colors.surface : Color.clear)
            }
        }
    }
    
    private var textColor: Color {
        switch variant {
        case .primary:
            return DesignSystem.Colors.textInverse
        case .secondary, .ghost:
            return DesignSystem.Colors.textPrimary
        }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(isPressed: Bool = false, isHovered: Bool = false) -> some View {
        modifier(CardStyle(isPressed: isPressed, isHovered: isHovered))
    }
    
    func buttonStyle_custom(_ variant: ButtonStyle_Custom.ButtonVariant) -> some View {
        buttonStyle(ButtonStyle_Custom(variant: variant))
    }
} 