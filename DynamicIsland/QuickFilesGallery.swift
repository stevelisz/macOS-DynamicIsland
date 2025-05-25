import SwiftUI
import AppKit
import Foundation

struct QuickFilesGallery: View {
    @Binding var quickFiles: [URL]
    let columns = [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: 16)]
    private func clearAll() {
        quickFiles.removeAll()
    }
    var body: some View {
        if quickFiles.isEmpty {
            ScrollView {
                VStack {
                    Text("Drop files here for quick access.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(16)
                }
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(quickFiles, id: \ .self) { url in
                        VStack(spacing: 6) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .cornerRadius(8)
                                .shadow(radius: 2, y: 1)
                            Text(url.lastPathComponent)
                                .font(.caption2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 80)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { NSWorkspace.shared.open(url) }
                        .onDrag { NSItemProvider(object: url as NSURL) }
                        .contextMenu {
                            Button(role: .destructive) {
                                if let idx = quickFiles.firstIndex(of: url) {
                                    quickFiles.remove(at: idx)
                                }
                            } label: {
                                Label("Remove File", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(16)
            }
            .contextMenu {
                if !quickFiles.isEmpty {
                    Button(role: .destructive) {
                        clearAll()
                    } label: {
                        Label("Remove All Files", systemImage: "trash")
                    }
                }
            }
        }
    }
} 
