import SwiftUI
import AppKit
import Foundation

struct QuickAppGallery: View {
    @Binding var quickApps: [URL]
    let columns = [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: 16)]
    private func clearAll() {
        quickApps.removeAll()
    }
    var body: some View {
        if quickApps.isEmpty {
            ScrollView {
                VStack {
                    Text("Drop applications here for quick access.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(16)
                }
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(quickApps, id: \.self) { url in
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 6) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(8)
                                    .shadow(radius: 2, y: 1)
                                Text(url.deletingPathExtension().lastPathComponent)
                                    .font(.caption2)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 80)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                NSWorkspace.shared.open(url)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let idx = quickApps.firstIndex(of: url) {
                                        quickApps.remove(at: idx)
                                    }
                                } label: {
                                    Label("Remove App", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .contextMenu {
                if !quickApps.isEmpty {
                    Button(role: .destructive) {
                        clearAll()
                    } label: {
                        Label("Remove All Apps", systemImage: "trash")
                    }
                }
            }
        }
    }
} 
