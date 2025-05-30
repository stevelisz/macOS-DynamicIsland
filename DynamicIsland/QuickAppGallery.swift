import SwiftUI
import AppKit
import Foundation

struct QuickAppGallery: View {
    @Binding var quickApps: [URL]
    let columns = [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: DesignSystem.Spacing.lg)]
    
    private func clearAll() {
        quickApps.removeAll()
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
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
                            .onTapGesture { NSWorkspace.shared.open(url) }
                            .contextMenu {
                                Button("Open") { NSWorkspace.shared.open(url) }
                                Divider()
                                Button("Remove", role: .destructive) {
                                    if let idx = quickApps.firstIndex(of: url) {
                                        quickApps.remove(at: idx)
                                    }
                                }
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                }
            }
        }
    }
}

