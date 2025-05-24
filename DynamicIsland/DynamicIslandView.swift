import SwiftUI

struct DynamicIslandView: View {
    @State private var isExpanded = false
    @State private var showContent = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Main island container
            RoundedRectangle(cornerRadius: isExpanded ? 28 : 18)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: isExpanded ? 28 : 18)
                        .stroke(.primary.opacity(0.1), lineWidth: 0.5)
                }
                .frame(
                    width: isExpanded ? 300 : 120,
                    height: isExpanded ? 200 : 35
                )
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.6 : 0.3),
                    radius: 15,
                    x: 0,
                    y: 8
                )
            
            // Content
            if showContent {
                if isExpanded {
                    expandedContent
                } else {
                    collapsedContent
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
            
            // Auto-expand after showing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isExpanded = true
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var collapsedContent: some View {
        HStack(spacing: 8) {
            // Activity indicator
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .scaleEffect(isExpanded ? 0 : 1)
            
            Text("Dynamic Island")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
        .transition(.opacity)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "macbook")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Island")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("macOS Enhanced")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: closeDynamicIsland) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .background(.clear)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Quick Actions
            VStack(spacing: 8) {
                quickActionRow(
                    "System Settings",
                    icon: "gearshape.fill",
                    color: .blue
                ) {
                    openSystemSettings()
                }
                
                quickActionRow(
                    "Activity Monitor",
                    icon: "speedometer",
                    color: .green
                ) {
                    openActivityMonitor()
                }
                
                quickActionRow(
                    "Terminal",
                    icon: "terminal.fill",
                    color: .orange
                ) {
                    openTerminal()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
    
    private func quickActionRow(
        _ title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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
