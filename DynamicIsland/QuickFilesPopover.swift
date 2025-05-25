import SwiftUI

struct QuickFilesPopover: View {
    @Binding var quickFiles: [URL]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Quick Files")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .padding(.horizontal, 12)
            Divider()
            if quickFiles.isEmpty {
                Text("Drop files here for quick access.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(16)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(quickFiles, id: \ .self) { url in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.accentColor)
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    if let idx = quickFiles.firstIndex(of: url) {
                                        quickFiles.remove(at: idx)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture { NSWorkspace.shared.open(url) }
                            .onDrag { NSItemProvider(object: url as NSURL) }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            DispatchQueue.main.async {
                                if !quickFiles.contains(url) {
                                    quickFiles.append(url)
                                }
                            }
                        } else if let url = item as? URL {
                            DispatchQueue.main.async {
                                if !quickFiles.contains(url) {
                                    quickFiles.append(url)
                                }
                            }
                        }
                    }
                }
            }
            return true
        }
    }
} 