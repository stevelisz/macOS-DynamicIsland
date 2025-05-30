import Foundation

extension UserDefaults {
    private static let quickAppsKey = "quickAppsBookmarks"
    
    var quickApps: [URL] {
        get {
            guard let data = data(forKey: Self.quickAppsKey),
                  let bookmarks = try? JSONDecoder().decode([Data].self, from: data) else {
                return []
            }
            
            var urls: [URL] = []
            for bookmark in bookmarks {
                var isStale = false
                if let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    urls.append(url)
                }
            }
            return urls
        }
        set {
            let bookmarks = newValue.compactMap { url -> Data? in
                // Create security-scoped bookmark
                return try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            }
            
            if let data = try? JSONEncoder().encode(bookmarks) {
                set(data, forKey: Self.quickAppsKey)
            }
        }
    }
    
    func removeQuickApp(at url: URL) {
        var currentApps = quickApps
        currentApps.removeAll { $0.path == url.path }
        quickApps = currentApps
    }
    
    func clearAllQuickApps() {
        // Stop accessing any security-scoped resources
        for url in quickApps {
            url.stopAccessingSecurityScopedResource()
        }
        removeObject(forKey: Self.quickAppsKey)
    }
} 