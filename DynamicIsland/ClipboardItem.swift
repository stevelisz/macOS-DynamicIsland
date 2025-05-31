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
    let content: String?          // For text
    let imageData: Data?          // For images
    private let fileBookmark: Data?   // Security-scoped bookmark for files
    private let fileURLString: String? // Backup URL string
    var date: Date
    var pinned: Bool

    // Computed property for secure file URL access
    var fileURL: URL? {
        guard type == .file else { return nil }
        
        // Try to resolve from security-scoped bookmark first
        if let bookmark = fileBookmark {
            var stale = false
            if let resolvedURL = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                if stale {
                    
                }
                return resolvedURL
            }
        }
        
        // Fallback to URL string (for compatibility)
        if let urlString = fileURLString {
            return URL(string: urlString)
        }
        
        return nil
    }

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

    // Initializers
    init(id: UUID = UUID(), type: ClipboardItemType, content: String? = nil, imageData: Data? = nil, fileURL: URL? = nil, date: Date = Date(), pinned: Bool = false) {
        self.id = id
        self.type = type
        self.content = content
        self.imageData = imageData
        self.date = date
        self.pinned = pinned
        
        // Handle file URL with security-scoped bookmark
        if let url = fileURL, type == .file {
            self.fileURLString = url.absoluteString
            do {
                self.fileBookmark = try url.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            } catch {
                
                self.fileBookmark = nil
            }
        } else {
            self.fileURLString = nil
            self.fileBookmark = nil
        }
    }
    
    // Method to access the file with proper security scoping
    func accessFile<T>(_ block: (URL) throws -> T) rethrows -> T? {
        guard let url = fileURL else { return nil }
        
        guard url.startAccessingSecurityScopedResource() else {
            
            return nil
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        return try block(url)
    }

    // Specialized method for pasteboard operations that maintains longer access
    func accessFileForPasteboard<T>(_ block: (URL) throws -> T) rethrows -> T? {
        guard let url = fileURL else { return nil }
        
        guard url.startAccessingSecurityScopedResource() else {
            
            return nil
        }
        
        // For pasteboard operations, keep access alive longer to allow cross-app transfers
        let result = try block(url)
        
        // Keep security-scoped access alive for 10 seconds to allow other apps to access
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            url.stopAccessingSecurityScopedResource()
        }
        
        return result
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