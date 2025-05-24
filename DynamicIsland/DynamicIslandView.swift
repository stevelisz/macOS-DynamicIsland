import SwiftUI

struct DynamicIslandView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showActionsPopover = false
    
    var body: some View {
        ZStack {
            // Main island container with enhanced blur and shadow
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.18))
                        .blur(radius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
                )
                .frame(width: 340, height: 240)
                .shadow(color: Color.black.opacity(0.25), radius: 32, x: 0, y: 16)
                .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 2)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "macbook")
                            .font(.title2)
                            .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dynamic Island")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("macOS Enhanced")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    // New icon for actions popover
                    Button(action: { showActionsPopover.toggle() }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color.accentColor)
                            .background(Color.clear)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .popover(isPresented: $showActionsPopover, arrowEdge: .top) {
                        VStack(spacing: 0) {
                            Text("Quick Actions")
                                .font(.headline)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            Divider()
                            VStack(spacing: 8) {
                                quickActionRow(
                                    "System Settings",
                                    icon: "gearshape.fill",
                                    color: LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                                ) {
                                    openSystemSettings()
                                    showActionsPopover = false
                                }
                                quickActionRow(
                                    "Activity Monitor",
                                    icon: "speedometer",
                                    color: LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                                ) {
                                    openActivityMonitor()
                                    showActionsPopover = false
                                }
                                quickActionRow(
                                    "Terminal",
                                    icon: "terminal.fill",
                                    color: LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                                ) {
                                    openTerminal()
                                    showActionsPopover = false
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                        }
                        .frame(width: 220)
                    }
                    Button(action: closeDynamicIsland) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color.secondary.opacity(0.7))
                            .background(Color.clear)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 8)
                
                // Separator
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                // Main content can go here (empty for now)
                Spacer()
            }
        }
        .frame(width: 340, height: 240)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: UUID())
    }
    
    private func quickActionRow(
        _ title: String,
        icon: String,
        color: LinearGradient,
        action: @escaping () -> Void
    ) -> some View {
        HoverableButton(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.secondary.opacity(0.7))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Actions
    private func closeDynamicIsland() {
        NotificationCenter.default.post(name: .closeDynamicIsland, object: nil)
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
        }
        closeDynamicIsland()
    }
    
    private func openActivityMonitor() {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"), configuration: configuration) { _, _ in }
        closeDynamicIsland()
    }
    
    private func openTerminal() {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"), configuration: configuration) { _, _ in }
        closeDynamicIsland()
    }
}

// Custom button style for scaling effect and hover effect
struct HoverableButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            label()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.10) : Color.primary.opacity(0.04))
                )
                .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.03 : 1.0))
                .opacity(isPressed ? 0.85 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isPressed)
                .animation(.easeOut(duration: 0.18), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .pressAction {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

// Helper for press action
struct PressActionModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() })
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressActionModifier(onPress: onPress, onRelease: onRelease))
    }
}
