import Foundation

enum ClipboardItemType: String, Codable {
    case text, image, file
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let content: String?      // For text
    let imageData: Data?      // For images
    let fileURL: URL?         // For files
    let date: Date
    var pinned: Bool

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
} 