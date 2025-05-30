import SwiftUI
import AppKit
import Foundation

struct QuickFilesGallery: View {
    @Binding var quickFiles: [URL]
    let columns = [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: DesignSystem.Spacing.lg)]
    
    private func clearAll() {
        quickFiles.removeAll()
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if quickFiles.isEmpty {
                // Empty state matching clipboard style
                VStack(spacing: DesignSystem.Spacing.md) {
                    Spacer()
                    
                    Image(systemName: "folder")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text("No quick files")
                        .font(DesignSystem.Typography.headline3)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Drop files here for quick access")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Content area - removed internal ScrollView
                LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.lg) {
                    ForEach(quickFiles, id: \.self) { url in
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
                            
                            Text(url.lastPathComponent)
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 80)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .contentShape(Rectangle())
                        .onTapGesture { NSWorkspace.shared.open(url) }
                        .onDrag { NSItemProvider(object: url as NSURL) }
                        .contextMenu {
                            Button("Open") { NSWorkspace.shared.open(url) }
                            Divider()
                            Button("Remove", role: .destructive) {
                                if let idx = quickFiles.firstIndex(of: url) {
                                    quickFiles.remove(at: idx)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 
