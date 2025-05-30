import Foundation

// MARK: - Security-Scoped Bookmark Support
struct SecureFileReference: Codable {
    let bookmark: Data
    let url: String
    let name: String
    let dateAdded: Date
    
    init(url: URL) throws {
        self.url = url.absoluteString
        self.name = url.lastPathComponent
        self.dateAdded = Date()
        self.bookmark = try url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
    
    func resolveURL() -> URL? {
        var stale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else {
            print("Failed to resolve bookmark for: \(name)")
            return nil
        }
        
        if stale {
            print("Bookmark is stale for: \(name)")
        }
        
        return resolvedURL
    }
}

extension UserDefaults {
    private static let quickFilesKey = "quickFilesBookmarks"
    private static let quickAppsKey = "quickAppsBookmarks"
    
    // MARK: - Quick Files with Security-Scoped Bookmarks
    var quickFiles: [URL] {
        get {
            guard let data = data(forKey: Self.quickFilesKey),
                  let references = try? JSONDecoder().decode([SecureFileReference].self, from: data) else { 
                return [] 
            }
            
            return references.compactMap { reference in
                guard let url = reference.resolveURL() else {
                    print("Could not resolve quick file: \(reference.name)")
                    return nil
                }
                
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    print("Could not start accessing security-scoped resource: \(reference.name)")
                    return nil
                }
                
                // Check if file still exists
                guard FileManager.default.fileExists(atPath: url.path) else {
                    url.stopAccessingSecurityScopedResource()
                    print("File no longer exists: \(reference.name)")
                    return nil
                }
                
                return url
            }
        }
        set {
            let references = newValue.compactMap { url -> SecureFileReference? in
                do {
                    return try SecureFileReference(url: url)
                } catch {
                    print("Failed to create security-scoped bookmark for \(url.lastPathComponent): \(error)")
                    return nil
                }
            }
            
            if let data = try? JSONEncoder().encode(references) {
                set(data, forKey: Self.quickFilesKey)
            }
        }
    }
    
    // MARK: - Quick Apps with Security-Scoped Bookmarks
    var quickApps: [URL] {
        get {
            guard let data = data(forKey: Self.quickAppsKey),
                  let references = try? JSONDecoder().decode([SecureFileReference].self, from: data) else { 
                return [] 
            }
            
            return references.compactMap { reference in
                guard let url = reference.resolveURL() else {
                    print("Could not resolve quick app: \(reference.name)")
                    return nil
                }
                
                // Verify it's still an app
                guard url.pathExtension == "app" else {
                    print("Quick app is no longer an application: \(reference.name)")
                    return nil
                }
                
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    print("Could not start accessing security-scoped resource: \(reference.name)")
                    return nil
                }
                
                // Check if app still exists
                guard FileManager.default.fileExists(atPath: url.path) else {
                    url.stopAccessingSecurityScopedResource()
                    print("App no longer exists: \(reference.name)")
                    return nil
                }
                
                return url
            }
        }
        set {
            let references = newValue.compactMap { url -> SecureFileReference? in
                // Only allow .app files
                guard url.pathExtension == "app" else { return nil }
                
                do {
                    return try SecureFileReference(url: url)
                } catch {
                    print("Failed to create security-scoped bookmark for \(url.lastPathComponent): \(error)")
                    return nil
                }
            }
            
            if let data = try? JSONEncoder().encode(references) {
                set(data, forKey: Self.quickAppsKey)
            }
        }
    }
    
    // MARK: - Cleanup Methods
    func removeQuickFile(at url: URL) {
        var currentFiles = quickFiles
        currentFiles.removeAll { $0.absoluteString == url.absoluteString }
        quickFiles = currentFiles
        
        // Stop accessing the security-scoped resource
        url.stopAccessingSecurityScopedResource()
    }
    
    func removeQuickApp(at url: URL) {
        var currentApps = quickApps
        currentApps.removeAll { $0.absoluteString == url.absoluteString }
        quickApps = currentApps
        
        // Stop accessing the security-scoped resource
        url.stopAccessingSecurityScopedResource()
    }
    
    func clearAllQuickFiles() {
        // Stop accessing all security-scoped resources
        for url in quickFiles {
            url.stopAccessingSecurityScopedResource()
        }
        removeObject(forKey: Self.quickFilesKey)
    }
    
    func clearAllQuickApps() {
        // Stop accessing all security-scoped resources
        for url in quickApps {
            url.stopAccessingSecurityScopedResource()
        }
        removeObject(forKey: Self.quickAppsKey)
    }
} 