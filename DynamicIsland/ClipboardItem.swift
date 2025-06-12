import Foundation
import CoreGraphics
import CryptoKit
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
    private let imageCachePath: String?    // Path to cached full image
    private let thumbnailCachePath: String? // Path to cached thumbnail
    private let fileBookmark: Data?   // Security-scoped bookmark for files
    private let fileURLString: String? // Backup URL string
    var date: Date
    var pinned: Bool
    
    // Fast lookup hash for O(1) deduplication
    let contentHash: String
    
    // Cache manager reference
    private static let cacheManager = ClipboardCacheManager.shared

    // MARK: - Computed Properties
    
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
                    print("⚠️ Security-scoped bookmark is stale for file: \(resolvedURL.lastPathComponent)")
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
    
    // Get thumbnail image (async)
    func thumbnailImage() async -> NSImage? {
        guard type == .image, let thumbnailPath = thumbnailCachePath else { return nil }
        return await Self.cacheManager.loadImage(from: thumbnailPath)
    }
    
    // Get full image (async)
    func fullImage() async -> NSImage? {
        guard type == .image, let imagePath = imageCachePath else { return nil }
        return await Self.cacheManager.loadImage(from: imagePath)
    }
    
    // Legacy imageData for compatibility (synchronous, use sparingly)
    var imageData: Data? {
        guard type == .image, let imagePath = imageCachePath else { return nil }
        return Self.cacheManager.loadImageDataSync(from: imagePath)
    }

    // MARK: - Initializers
    
    init(id: UUID = UUID(), type: ClipboardItemType, content: String? = nil, imageData: Data? = nil, fileURL: URL? = nil, date: Date = Date(), pinned: Bool = false) {
        self.id = id
        self.type = type
        self.content = content
        self.date = date
        self.pinned = pinned
        
        // Generate content hash for O(1) deduplication
        switch type {
        case .text:
            self.contentHash = Self.generateTextHash(content)
        case .image:
            self.contentHash = Self.generateImageHash(imageData)
        case .file:
            self.contentHash = Self.generateFileHash(fileURL)
        }
        
        // Handle image caching
        if let data = imageData, type == .image {
            let paths = Self.cacheManager.cacheImage(data, contentHash: contentHash)
            self.imageCachePath = paths.fullImagePath
            self.thumbnailCachePath = paths.thumbnailPath
        } else {
            self.imageCachePath = nil
            self.thumbnailCachePath = nil
        }
        
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
                print("⚠️ Failed to create security-scoped bookmark for: \(url.lastPathComponent)")
                self.fileBookmark = nil
            }
        } else {
            self.fileURLString = nil
            self.fileBookmark = nil
        }
    }
    
    // MARK: - Hash Generation (for O(1) deduplication)
    
    private static func generateTextHash(_ text: String?) -> String {
        guard let text = text, let data = text.data(using: .utf8) else { return UUID().uuidString }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private static func generateImageHash(_ data: Data?) -> String {
        guard let data = data else { return UUID().uuidString }
        // Use first and last 1KB + size for fast hashing while keeping hash short
        let size = data.count
        let prefix = data.prefix(1024)
        let suffix = data.suffix(1024)
        let combined = prefix + suffix + "\(size)".data(using: .utf8)!
        let hash = SHA256.hash(data: combined)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private static func generateFileHash(_ url: URL?) -> String {
        guard let url = url, let data = "\(url.absoluteString)_\(url.lastPathComponent)".data(using: .utf8) else { 
            return UUID().uuidString 
        }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - File Access Methods
    
    // Method to access the file with proper security scoping
    func accessFile<T>(_ block: (URL) throws -> T) rethrows -> T? {
        guard let url = fileURL else { return nil }
        
        guard url.startAccessingSecurityScopedResource() else {
            print("⚠️ Failed to access security-scoped resource: \(url.lastPathComponent)")
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
            print("⚠️ Failed to access security-scoped resource for pasteboard: \(url.lastPathComponent)")
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

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - High-Performance Cache Manager

class ClipboardCacheManager: ObservableObject {
    static let shared = ClipboardCacheManager()
    
    nonisolated private let cacheDirectory: URL
    nonisolated private let thumbnailSize: CGSize = CGSize(width: 200, height: 200)
    private let maxCacheSize: Int64 = 500 * 1024 * 1024 // 500MB
    
    // In-memory cache for frequently accessed thumbnails
    private var thumbnailCache: [String: NSImage] = [:]
    private let maxMemoryCache = 50
    
    private init() {
        // Create cache directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = appSupport.appendingPathComponent("DynamicIsland/ClipboardCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Start background cleanup
        Task.detached { [weak self] in
            await self?.performBackgroundCleanup()
        }
    }
    
    // MARK: - Cache Image (Background Operation)
    
    func cacheImage(_ data: Data, contentHash: String) -> (fullImagePath: String, thumbnailPath: String) {
        let fullImagePath = "full_\(contentHash).png"
        let thumbnailPath = "thumb_\(contentHash).png"
        
        // Cache synchronously to ensure images are available when UI loads
        performImageCachingSync(data, fullImagePath: fullImagePath, thumbnailPath: thumbnailPath)
        
        return (fullImagePath, thumbnailPath)
    }
    
    private func performImageCachingSync(_ data: Data, fullImagePath: String, thumbnailPath: String) {
        let fullURL = cacheDirectory.appendingPathComponent(fullImagePath)
        let thumbnailURL = cacheDirectory.appendingPathComponent(thumbnailPath)
        
        // Skip if already cached
        if FileManager.default.fileExists(atPath: fullURL.path) && 
           FileManager.default.fileExists(atPath: thumbnailURL.path) {
            return
        }
        
        guard let image = NSImage(data: data) else { return }
        
        // Save full image in original format (preserve original data)
        try? data.write(to: fullURL)
        
        // Generate and save thumbnail as PNG
        let thumbnail = generateThumbnailSync(from: image)
        if let thumbnailData = thumbnail.tiffRepresentation,
           let thumbnailBitmap = NSBitmapImageRep(data: thumbnailData),
           let thumbnailPNG = thumbnailBitmap.representation(using: .png, properties: [:]) {
            try? thumbnailPNG.write(to: thumbnailURL)
            
            // Cache in memory for immediate access
            Task { @MainActor in
                self.thumbnailCache[thumbnailPath] = thumbnail
                self.evictOldThumbnails()
            }
        }
    }
    
    private func performImageCaching(_ data: Data, fullImagePath: String, thumbnailPath: String) async {
        let fullURL = cacheDirectory.appendingPathComponent(fullImagePath)
        let thumbnailURL = cacheDirectory.appendingPathComponent(thumbnailPath)
        
        // Skip if already cached
        if FileManager.default.fileExists(atPath: fullURL.path) && 
           FileManager.default.fileExists(atPath: thumbnailURL.path) {
            return
        }
        
        guard let image = NSImage(data: data) else { return }
        
        // Save full image in original format (preserve original data)
        try? data.write(to: fullURL)
        
        // Generate and save thumbnail
        let thumbnail = await generateThumbnail(from: image)
        if let thumbnailData = thumbnail.tiffRepresentation,
           let thumbnailBitmap = NSBitmapImageRep(data: thumbnailData),
           let thumbnailPNG = thumbnailBitmap.representation(using: .png, properties: [:]) {
            try? thumbnailPNG.write(to: thumbnailURL)
            
            // Cache in memory for immediate access
            await MainActor.run {
                self.thumbnailCache[thumbnailPath] = thumbnail
                self.evictOldThumbnails()
            }
        }
    }
    
    // MARK: - Load Images (Async)
    
    func loadImage(from path: String) async -> NSImage? {
        let url = cacheDirectory.appendingPathComponent(path)
        
        // Check memory cache first (on main actor)
        let cachedImage = await MainActor.run {
            thumbnailCache[path]
        }
        
        if let cachedImage = cachedImage {
            return cachedImage
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = NSImage(contentsOf: url)
                if let image = image {
                    // Cache it in memory for next time
                    Task { @MainActor in
                        self.thumbnailCache[path] = image
                        self.evictOldThumbnails()
                    }
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    // Legacy sync method (use sparingly)
    nonisolated func loadImageDataSync(from path: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(path)
        return try? Data(contentsOf: url)
    }
    
    // MARK: - Thumbnail Generation
    
    private func generateThumbnailSync(from image: NSImage) -> NSImage {
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize))
        thumbnail.unlockFocus()
        return thumbnail
    }
    
    private func generateThumbnail(from image: NSImage) async -> NSImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async { [thumbnailSize] in
                let thumbnail = NSImage(size: thumbnailSize)
                thumbnail.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: thumbnailSize))
                thumbnail.unlockFocus()
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    // MARK: - Memory Management
    
    private func evictOldThumbnails() {
        if thumbnailCache.count > maxMemoryCache {
            let keysToRemove = Array(thumbnailCache.keys.prefix(thumbnailCache.count - maxMemoryCache))
            keysToRemove.forEach { thumbnailCache.removeValue(forKey: $0) }
        }
    }
    
    // MARK: - Background Cleanup
    
    private func performBackgroundCleanup() async {
        // Run cleanup every 5 minutes
        while true {
            try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000) // 5 minutes
            await cleanupOldCache()
        }
    }
    
    private func cleanupOldCache() async {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: cacheDirectory.path) else { return }
        
        var totalSize: Int64 = 0
        var fileInfos: [(url: URL, date: Date, size: Int64)] = []
        
        // Calculate total size and collect file info
        for file in files {
            let url = cacheDirectory.appendingPathComponent(file)
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64,
               let date = attrs[.modificationDate] as? Date {
                totalSize += size
                fileInfos.append((url, date, size))
            }
        }
        
        // Remove oldest files if over cache limit
        if totalSize > maxCacheSize {
            fileInfos.sort { $0.date < $1.date }
            var currentSize = totalSize
            
            for fileInfo in fileInfos {
                if currentSize <= maxCacheSize { break }
                try? fileManager.removeItem(at: fileInfo.url)
                currentSize -= fileInfo.size
            }
        }
    }
} 