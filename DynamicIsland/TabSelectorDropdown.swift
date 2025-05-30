import SwiftUI

struct TabSelectorDropdown: View {
    @Binding var selectedView: MainViewType
    @Binding var enabledTabs: Set<MainViewType>
    
    private let tabs: [(MainViewType, String, String, Color)] = [
        (.clipboard, "doc.on.clipboard.fill", "Clipboard", DesignSystem.Colors.clipboard),
        (.quickApp, "app.fill", "Apps", DesignSystem.Colors.apps),
        (.systemMonitor, "gauge.high", "System", DesignSystem.Colors.system),
        (.weather, "cloud.sun.fill", "Weather", DesignSystem.Colors.primary)
    ]
    
    var body: some View {
        Menu {
            ForEach(tabs, id: \.0.hashValue) { tab in
                Button(action: {
                    toggleTab(tab.0)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.1)
                            .foregroundColor(tab.3)
                        
                        Text("\(tab.2)\(enabledTabs.contains(tab.0) ? " ✓" : "")")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(enabledTabs.contains(tab.0) ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            Divider()
            
            Button("Enable All") {
                enabledTabs = Set(tabs.map { $0.0 })
            }
            
            Button("Disable All") {
                // Keep at least one tab enabled (clipboard as fallback)
                enabledTabs = Set([.clipboard])
                if selectedView != .clipboard {
                    selectedView = .clipboard
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .background(
                    Circle()
                        .fill(DesignSystem.Colors.surface.opacity(0.1))
                        .frame(width: 24, height: 24)
                )
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 0.5)
                        .frame(width: 24, height: 24)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .menuStyle(BorderlessButtonMenuStyle())
        .menuIndicator(.hidden)
        .frame(width: 28, height: 28)
        .clipped()
        .animation(DesignSystem.Animation.smooth, value: enabledTabs)
    }
    
    private func toggleTab(_ tab: MainViewType) {
        if enabledTabs.contains(tab) {
            // Don't allow disabling if it's the only enabled tab
            if enabledTabs.count > 1 {
                enabledTabs.remove(tab)
                // If we disabled the currently selected tab, switch to the first available tab
                if selectedView == tab {
                    selectedView = enabledTabs.first ?? .clipboard
                }
            }
        } else {
            enabledTabs.insert(tab)
        }
    }
}

// Extension to make MainViewType hashable for ForEach
extension MainViewType: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .clipboard:
            hasher.combine(0)
        case .quickApp:
            hasher.combine(1)
        case .systemMonitor:
            hasher.combine(2)
        case .weather:
            hasher.combine(3)
        }
    }
} 