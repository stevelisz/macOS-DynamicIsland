import Foundation

extension UserDefaults {
    private static let quickFilesKey = "quickFilesKey"
    private static let quickAppsKey = "quickAppsKey"
    var quickFiles: [URL] {
        get {
            guard let data = data(forKey: Self.quickFilesKey),
                  let strings = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return strings.compactMap { URL(string: $0) }.filter { $0 != nil }.map { $0! }
        }
        set {
            let strings = newValue.map { $0.absoluteString }
            if let data = try? JSONEncoder().encode(strings) {
                set(data, forKey: Self.quickFilesKey)
            }
        }
    }
    var quickApps: [URL] {
        get {
            guard let data = data(forKey: Self.quickAppsKey),
                  let strings = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return strings.compactMap { URL(string: $0) }.filter { $0.pathExtension == "app" }.map { $0 }
        }
        set {
            let strings = newValue.map { $0.absoluteString }
            if let data = try? JSONEncoder().encode(strings) {
                set(data, forKey: Self.quickAppsKey)
            }
        }
    }
} 