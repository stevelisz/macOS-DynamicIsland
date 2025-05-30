import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

enum ClipboardItemType: String, Codable {
    case text, image, file
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let content: String?      // For text
    let imageData: Data?      // For images
    let fileURL: URL?         // For files
    var date: Date
    var pinned: Bool

    // Computed property for image pixel hash (not codable)
    var imagePixelHash: Int? {
        guard type == .image, let data = imageData else { return nil }
        #if canImport(AppKit)
        if let img = NSImage(data: data) {
            return ClipboardItem.pixelHash(for: img)
        }
        #endif
        return nil
    }

    static func pixelHash(for image: NSImage) -> Int {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return 0 }
        let width = Int(bitmap.pixelsWide)
        let height = Int(bitmap.pixelsHigh)
        var hash = 5381
        for y in 0..<height {
            for x in 0..<width {
                let color = bitmap.colorAt(x: x, y: y) ?? .clear
                let r = Int((color.redComponent * 255).rounded())
                let g = Int((color.greenComponent * 255).rounded())
                let b = Int((color.blueComponent * 255).rounded())
                let a = Int((color.alphaComponent * 255).rounded())
                hash = ((hash << 5) &+ hash) &+ r &+ g &+ b &+ a
            }
        }
        return hash
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
} 