import Foundation
import SwiftUI

@MainActor
class OllamaService: ObservableObject {
    @Published var isConnected = false
    @Published var isChecking = false
    @Published var availableModels: [String] = []
    @Published var selectedModel = "llama3.2:3b"
    @Published var conversationHistory: [ChatMessage] = []
    @Published var isGenerating = false
    
    private let baseURL = "http://localhost:11434"
    private var quickSession: URLSession // For quick operations like version/tags
    private var generateSession: URLSession // For slower generate operations
    
    init() {
        // Quick session for version/tags (5 second timeout)
        let quickConfig = URLSessionConfiguration.default
        quickConfig.timeoutIntervalForRequest = 5.0
        quickConfig.timeoutIntervalForResource = 10.0
        self.quickSession = URLSession(configuration: quickConfig)
        
        // Generate session for model inference (longer timeout)
        let generateConfig = URLSessionConfiguration.default
        generateConfig.timeoutIntervalForRequest = 120.0 // 2 minutes
        generateConfig.timeoutIntervalForResource = 300.0 // 5 minutes
        self.generateSession = URLSession(configuration: generateConfig)
    }
    
    // MARK: - Connection Management
    
    func checkConnection() async {
        isChecking = true
        defer { isChecking = false }
        
        do {
            let url = URL(string: "\(baseURL)/api/version")!
            let (_, response) = try await quickSession.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                isConnected = true
                await loadAvailableModels()
            } else {
                isConnected = false
            }
        } catch {
            isConnected = false
        }
    }
    
    func loadAvailableModels() async {
        guard isConnected else { return }
        
        do {
            let url = URL(string: "\(baseURL)/api/tags")!
            let (data, _) = try await quickSession.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { $0["name"] as? String }
                availableModels = modelNames.sorted()
                
                // Set default model if available - prefer smaller models for better performance
                if !modelNames.isEmpty {
                    if !modelNames.contains(selectedModel) {
                        // Prefer smaller, faster models
                        if let smallModel = modelNames.first(where: { $0.contains("3b") || $0.contains("7b") }) {
                            selectedModel = smallModel
                        } else {
                            selectedModel = modelNames.first ?? "llama3.2:3b"
                        }
                    }
                }
            }
        } catch {
            availableModels = []
        }
    }
    
    // MARK: - Chat Methods
    
    func sendMessage(_ message: String) async -> String {
        guard isConnected else { return "Error: Ollama is not connected" }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let userMessage = ChatMessage(role: .user, content: message)
        conversationHistory.append(userMessage)
        
        do {
            let url = URL(string: "\(baseURL)/api/generate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Simplified request body without context for now
            let requestBody: [String: Any] = [
                "model": selectedModel,
                "prompt": message,
                "stream": false
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await generateSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorMessage = json["error"] as? String {
                    return "Error: \(errorMessage)"
                }
                
                if let responseText = json["response"] as? String {
                    let assistantMessage = ChatMessage(role: .assistant, content: responseText)
                    conversationHistory.append(assistantMessage)
                    return responseText
                }
            }
            
        } catch {
            let errorMsg = error.localizedDescription
            if errorMsg.contains("timed out") {
                return "Error: Request timed out. The model might be too large or not loaded. Try a smaller model."
            } else if errorMsg.contains("Connection refused") {
                return "Error: Connection refused. Make sure Ollama is running with 'ollama serve'."
            }
            return "Error: \(errorMsg)"
        }
        
        return "Error: Failed to get response from model"
    }
    
    func sendStreamingMessage(_ message: String, onUpdate: @escaping (String) -> Void) async {
        guard isConnected else { 
            onUpdate("Error: Ollama is not connected")
            return 
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let userMessage = ChatMessage(role: .user, content: message)
        conversationHistory.append(userMessage)
        
        do {
            let url = URL(string: "\(baseURL)/api/generate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Simplified request body
            let requestBody: [String: Any] = [
                "model": selectedModel,
                "prompt": message,
                "stream": true
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (bytes, _) = try await generateSession.bytes(for: request)
            var fullResponse = ""
            
            for try await line in bytes.lines {
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    if let errorMessage = json["error"] as? String {
                        onUpdate("Error: \(errorMessage)")
                        return
                    }
                    
                    if let response = json["response"] as? String {
                        fullResponse += response
                        onUpdate(fullResponse)
                    }
                    
                    // Check if this is the final message
                    if let done = json["done"] as? Bool, done {
                        break
                    }
                }
            }
            
            if !fullResponse.isEmpty {
                let assistantMessage = ChatMessage(role: .assistant, content: fullResponse)
                conversationHistory.append(assistantMessage)
            }
            
        } catch {
            let errorMsg = error.localizedDescription
            if errorMsg.contains("timed out") {
                onUpdate("Error: Request timed out. The model might be too large or not loaded. Try a smaller model.")
            } else if errorMsg.contains("Connection refused") {
                onUpdate("Error: Connection refused. Make sure Ollama is running with 'ollama serve'.")
            } else {
                onUpdate("Error: \(errorMsg)")
            }
        }
    }
    
    // MARK: - Specialized AI Tools
    
    func processCode(code: String, task: CodeTask) async -> String {
        let prompt = task.buildPrompt(for: code)
        return await sendMessage(prompt)
    }
    
    func processText(text: String, task: TextTask) async -> String {
        let prompt = task.buildPrompt(for: text)
        return await sendMessage(prompt)
    }
    
    func explainError(error: String) async -> String {
        let prompt = """
        Please analyze this error message and provide:
        1. What the error means in simple terms
        2. Common causes of this error
        3. Suggested solutions or debugging steps
        
        Error: \(error)
        """
        return await sendMessage(prompt)
    }
    
    // MARK: - Helper Methods
    
    private func buildContext() -> [String] {
        // Build context from recent conversation history
        let recentMessages = conversationHistory.suffix(10) // Last 10 messages
        return recentMessages.map { "\($0.role.rawValue): \($0.content)" }
    }
    
    func clearConversation() {
        conversationHistory.removeAll()
    }
}

// MARK: - Models

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}

enum MessageRole: String, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "AI"
        }
    }
}

enum CodeTask: String, CaseIterable {
    case explain = "Explain Code"
    case review = "Code Review"
    case optimize = "Optimize"
    case debug = "Debug"
    case document = "Generate Docs"
    case refactor = "Refactor"
    
    func buildPrompt(for code: String) -> String {
        switch self {
        case .explain:
            return "Please explain what this code does in detail:\n\n```\n\(code)\n```"
        case .review:
            return "Please review this code and suggest improvements:\n\n```\n\(code)\n```"
        case .optimize:
            return "Please suggest optimizations for this code:\n\n```\n\(code)\n```"
        case .debug:
            return "Please help debug this code and identify potential issues:\n\n```\n\(code)\n```"
        case .document:
            return "Please generate documentation for this code:\n\n```\n\(code)\n```"
        case .refactor:
            return "Please suggest how to refactor this code for better structure:\n\n```\n\(code)\n```"
        }
    }
}

enum TextTask: String, CaseIterable {
    case summarize = "Summarize"
    case translate = "Translate"
    case rewrite = "Rewrite"
    case expand = "Expand"
    case simplify = "Simplify"
    case tone = "Change Tone"
    
    func buildPrompt(for text: String) -> String {
        switch self {
        case .summarize:
            return "Please provide a concise summary of this text:\n\n\(text)"
        case .translate:
            return "Please translate this text to English (or detect the language and translate appropriately):\n\n\(text)"
        case .rewrite:
            return "Please rewrite this text to be clearer and more professional:\n\n\(text)"
        case .expand:
            return "Please expand on this text with more details and context:\n\n\(text)"
        case .simplify:
            return "Please simplify this text to make it easier to understand:\n\n\(text)"
        case .tone:
            return "Please rewrite this text with a more professional and friendly tone:\n\n\(text)"
        }
    }
} 
