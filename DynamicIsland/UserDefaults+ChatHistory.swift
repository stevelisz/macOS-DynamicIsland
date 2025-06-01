import Foundation

// MARK: - Chat Conversation Models

struct ChatConversation: Codable, Identifiable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var lastModified: Date
    
    init(title: String = "New Chat", messages: [ChatMessage] = []) {
        self.id = UUID()
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // Generate a smart title from the first user message
    mutating func generateTitle() {
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            var content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Clean up common formatting that makes titles messy
            content = content.replacingOccurrences(of: "**", with: "") // Remove bold markdown
            content = content.replacingOccurrences(of: "```", with: "") // Remove code blocks
            content = content.replacingOccurrences(of: "*", with: "") // Remove italic markdown
            content = content.replacingOccurrences(of: "`", with: "") // Remove inline code
            content = content.replacingOccurrences(of: "\n", with: " ") // Replace newlines with spaces
            content = content.replacingOccurrences(of: "  ", with: " ") // Clean up double spaces
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract filename if it looks like a file reference
            if content.contains(".") && content.count > 30 {
                // Look for file extensions
                let commonExtensions = [".txt", ".md", ".swift", ".py", ".js", ".html", ".css", ".json", ".xml", ".jpg", ".png", ".gif", ".pdf"]
                for ext in commonExtensions {
                    if let range = content.range(of: ext, options: .caseInsensitive) {
                        // Find the filename before the extension
                        let beforeExt = content[..<range.lowerBound]
                        if let lastSpace = beforeExt.lastIndex(of: " ") {
                            let filename = String(beforeExt[beforeExt.index(after: lastSpace)...]) + ext
                            self.title = filename
                            return
                        }
                    }
                }
            }
            
            // For regular messages, take first meaningful words
            let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            if words.count > 6 {
                self.title = words.prefix(6).joined(separator: " ") + "..."
            } else if content.count > 35 {
                self.title = String(content.prefix(32)) + "..."
            } else {
                self.title = content.isEmpty ? "Empty Chat" : content
            }
        } else {
            self.title = "New Chat"
        }
    }
    
    var preview: String {
        if let lastMessage = messages.last {
            let content = lastMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return content.count > 100 ? String(content.prefix(97)) + "..." : content
        }
        return "No messages"
    }
    
    var messageCount: Int {
        return messages.count
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastModified)
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    private enum Keys {
        static let chatConversations = "chatConversations"
        static let currentConversationId = "currentConversationId"
        static let maxConversations = "maxConversations"
    }
    
    // MARK: - Chat Conversations
    
    var chatConversations: [ChatConversation] {
        get {
            guard let data = data(forKey: Keys.chatConversations),
                  let conversations = try? JSONDecoder().decode([ChatConversation].self, from: data) else {
                return []
            }
            return conversations.sorted { $0.lastModified > $1.lastModified }
        }
        set {
            // Limit to maximum number of conversations (default 50)
            let maxConversations = maxStoredConversations
            let limitedConversations = Array(newValue.sorted { $0.lastModified > $1.lastModified }.prefix(maxConversations))
            
            if let data = try? JSONEncoder().encode(limitedConversations) {
                set(data, forKey: Keys.chatConversations)
            }
        }
    }
    
    var currentConversationId: UUID? {
        get {
            guard let uuidString = string(forKey: Keys.currentConversationId) else { return nil }
            return UUID(uuidString: uuidString)
        }
        set {
            set(newValue?.uuidString, forKey: Keys.currentConversationId)
        }
    }
    
    var maxStoredConversations: Int {
        get {
            let value = integer(forKey: Keys.maxConversations)
            return value == 0 ? 50 : value // Default to 50 if not set
        }
        set {
            set(newValue, forKey: Keys.maxConversations)
        }
    }
    
    // MARK: - Chat Management Methods
    
    func saveConversation(_ conversation: ChatConversation) {
        var conversations = chatConversations
        
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            // Update existing conversation
            conversations[index] = conversation
        } else {
            // Add new conversation
            conversations.append(conversation)
        }
        
        chatConversations = conversations
    }
    
    func deleteConversation(id: UUID) {
        var conversations = chatConversations
        conversations.removeAll { $0.id == id }
        chatConversations = conversations
        
        // Clear current conversation if it was deleted
        if currentConversationId == id {
            currentConversationId = nil
        }
    }
    
    func getConversation(id: UUID) -> ChatConversation? {
        return chatConversations.first { $0.id == id }
    }
    
    func createNewConversation(title: String = "New Chat") -> ChatConversation {
        let conversation = ChatConversation(title: title)
        saveConversation(conversation)
        currentConversationId = conversation.id
        return conversation
    }
    
    func clearAllConversations() {
        chatConversations = []
        currentConversationId = nil
    }
    
    func getCurrentConversation() -> ChatConversation? {
        guard let currentId = currentConversationId else { return nil }
        return getConversation(id: currentId)
    }
    
    func searchConversations(query: String) -> [ChatConversation] {
        let lowercaseQuery = query.lowercased()
        return chatConversations.filter { conversation in
            conversation.title.lowercased().contains(lowercaseQuery) ||
            conversation.messages.contains { message in
                message.content.lowercased().contains(lowercaseQuery)
            }
        }
    }
}

// MARK: - ChatMessage Extension for Persistence

extension ChatMessage: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role.rawValue, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let roleString = try container.decode(String.self, forKey: .role)
        let role = MessageRole(rawValue: roleString) ?? .user
        let content = try container.decode(String.self, forKey: .content)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        self.init(id: id, role: role, content: content, timestamp: timestamp)
    }
} 