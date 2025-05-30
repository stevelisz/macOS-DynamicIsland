import SwiftUI
import AppKit
import Foundation

struct QuickAppGallery: View {
    @Binding var quickApps: [URL]
    let columns = [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: DesignSystem.Spacing.lg)]
    
    private func clearAll() {
        UserDefaults.standard.clearAllQuickApps()
        quickApps = UserDefaults.standard.quickApps
    }
    
    private func removeApp(_ url: URL) {
        UserDefaults.standard.removeQuickApp(at: url)
        quickApps = UserDefaults.standard.quickApps
    }
    
    private func openApp(_ url: URL) {
        // Ensure we have security-scoped access
        guard url.startAccessingSecurityScopedResource() else {
            print("Could not start accessing security-scoped resource for: \(url.lastPathComponent)")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        NSWorkspace.shared.open(url)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if quickApps.isEmpty {
                // Empty state matching clipboard style
                VStack(spacing: DesignSystem.Spacing.md) {
                    Spacer()
                    
                    Image(systemName: "app")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text("No quick apps")
                        .font(DesignSystem.Typography.headline3)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Drop applications here for quick access")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Content area - removed internal ScrollView
                LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.lg) {
                    ForEach(quickApps, id: \.self) { url in
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .cornerRadius(DesignSystem.BorderRadius.sm)
                                .shadow(
                                    color: DesignSystem.Shadows.sm.color,
                                    radius: DesignSystem.Shadows.sm.radius,
                                    x: DesignSystem.Shadows.sm.x,
                                    y: DesignSystem.Shadows.sm.y
                                )
                            
                            Text(url.deletingPathExtension().lastPathComponent)
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 80)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .contentShape(Rectangle())
                        .onTapGesture { openApp(url) }
                        .contextMenu {
                            Button("Open") { openApp(url) }
                            Divider()
                            Button("Remove", role: .destructive) {
                                removeApp(url)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .contentShape(Rectangle())
        .contextMenu {
            if !quickApps.isEmpty {
                Button("Clear All Quick Apps", role: .destructive) {
                    clearAll()
                }
            }
        }
    }
}

