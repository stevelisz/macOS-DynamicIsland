import Foundation
import SwiftUI
import Darwin

@MainActor
class OllamaService: ObservableObject {
    @Published var isConnected = false
    @Published var isChecking = false
    @Published var availableModels: [OllamaModel] = []
    @Published var selectedModel = "llama3.2:3b"
    @Published var conversationHistory: [ChatMessage] = []
    @Published var isGenerating = false
    @Published var generatingConversationId: UUID?
    @Published var currentConversation: ChatConversation?
    @Published var supportedFileTypes: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "txt", "md", "swift", "py", "js", "html", "css", "json", "xml"]
    
    // Web Search Integration
    @Published var webSearchService = WebSearchService()
    @Published var webSearchEnabled: Bool {
        didSet {
            UserDefaults.standard.webSearchEnabled = webSearchEnabled
        }
    }
    
    // Computed properties for compatibility with ExpandedAIAssistantView
    var currentModel: OllamaModel? {
        get {
            availableModels.first { $0.name == selectedModel }.map { $0 }
        }
        set {
            if let newValue = newValue {
                selectedModel = newValue.name
            }
        }
    }
    
    var messages: [ChatMessage] {
        return conversationHistory
    }
    
    // Computed property to check if Ollama is connected but no models are available
    var isConnectedButNoModels: Bool {
        return isConnected && availableModels.isEmpty
    }
    
    // Computed property to check if we're ready to chat (connected and have models)
    var isReadyToChat: Bool {
        return isConnected && !availableModels.isEmpty
    }
    
    private let baseURL = "http://localhost:11434"
    private var quickSession: URLSession // For quick operations like version/tags
    private var generateSession: URLSession // For slower generate operations
    
    // Vision model capabilities
    var isVisionModel: Bool {
        let visionModels = ["llava", "bakllava", "moondream"]
        return visionModels.contains { selectedModel.lowercased().contains($0) }
    }
    
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
        
        // Initialize web search setting
        self.webSearchEnabled = UserDefaults.standard.webSearchEnabled
        
        // Load or create initial conversation
        loadCurrentConversation()
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
                availableModels = modelNames.sorted().map { OllamaModel(name: $0) }
                
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
    
    func clearMessages() {
        conversationHistory.removeAll()
        saveCurrentConversation()
    }
    
    func loadModels() async {
        await loadAvailableModels()
    }
    
    func sendMessage(_ message: String) async -> String {
        guard isConnected else { return "Error: Ollama is not connected" }
        guard !availableModels.isEmpty else { 
            return "Error: No AI models are available. Please download a model first using 'ollama pull llama3.2:3b' in Terminal."
        }
        
        // Prevent race condition by capturing the current conversation ID
        guard let originalConversationId = currentConversation?.id else {
            return "Error: No active conversation"
        }
        
        // Add user message first, before setting isGenerating
        let userMessage = ChatMessage(role: .user, content: message)
        conversationHistory.append(userMessage)
        saveCurrentConversation()
        
        // Give a small delay to ensure UI updates before showing AI thinking indicator
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        
        // Now set generating state after user message is in conversation
        isGenerating = true
        generatingConversationId = originalConversationId
        defer { 
            isGenerating = false
            generatingConversationId = nil
        }
        
        // Enhance query with web search if enabled
        let enhancedMessage = await enhanceMessageWithWebSearch(message)
        
        do {
            let url = URL(string: "\(baseURL)/api/generate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Build context with conversation history
            let contextualPrompt = buildContextualPrompt(for: enhancedMessage)
            
            let requestBody: [String: Any] = [
                "model": selectedModel,
                "prompt": contextualPrompt,
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
                    // Ensure response goes to the original conversation
                    await saveResponseToConversation(responseText, conversationId: originalConversationId)
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
        guard !availableModels.isEmpty else {
            onUpdate("Error: No AI models are available. Please download a model first using 'ollama pull llama3.2:3b' in Terminal.")
            return
        }
        
        // Prevent race condition by capturing the current conversation ID
        guard let originalConversationId = currentConversation?.id else {
            onUpdate("Error: No active conversation")
            return
        }
        
        // Add user message first, before setting isGenerating
        let userMessage = ChatMessage(role: .user, content: message)
        conversationHistory.append(userMessage)
        saveCurrentConversation()
        
        // Give a small delay to ensure UI updates before showing AI thinking indicator
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        
        // Now set generating state after user message is in conversation
        isGenerating = true
        generatingConversationId = originalConversationId
        defer { 
            isGenerating = false
            generatingConversationId = nil
        }
        
        // Enhance query with web search if enabled
        let enhancedMessage = await enhanceMessageWithWebSearch(message)
        
        do {
            let url = URL(string: "\(baseURL)/api/generate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Build context with conversation history
            let contextualPrompt = buildContextualPrompt(for: enhancedMessage)
            
            let requestBody: [String: Any] = [
                "model": selectedModel,
                "prompt": contextualPrompt,
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
                // Ensure response goes to the original conversation
                await saveResponseToConversation(fullResponse, conversationId: originalConversationId)
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
    
    // MARK: - Web Search Integration
    
    private func enhanceMessageWithWebSearch(_ message: String) async -> String {
        guard webSearchEnabled else { return message }
        
        // Check if this query would benefit from web search
        if webSearchService.shouldSuggestWebSearch(message) {
            let enhanced = await webSearchService.enhanceQueryWithSearch(
                originalQuery: message,
                searchProvider: UserDefaults.standard.webSearchProvider
            )
            return enhanced
        }
        
        return message
    }
    
    func toggleWebSearch() {
        webSearchEnabled.toggle()
        // Sync with UserDefaults so web search actually works
        UserDefaults.standard.webSearchEnabled = webSearchEnabled
    }
    
    // MARK: - Specialized AI Tools
    
    func processCode(code: String, task: CodeTask) async -> String {
        let prompt = task.buildPrompt(for: code)
        return await executeQuickPrompt(prompt)
    }
    
    func processText(text: String, task: TextTask) async -> String {
        let prompt = task.buildPrompt(for: text)
        return await executeQuickPrompt(prompt)
    }
    
    // Execute a prompt without adding to conversation history
    private func executeQuickPrompt(_ prompt: String) async -> String {
        guard isConnected else { return "Error: Ollama is not connected" }
        guard !availableModels.isEmpty else { 
            return "Error: No AI models are available. Please download a model first using 'ollama pull llama3.2:3b' in Terminal."
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/generate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "model": selectedModel,
                "prompt": prompt,
                "stream": false
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await generateSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Quick Prompt Response Status: \(httpResponse.statusCode)")
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorMessage = json["error"] as? String {
                    return "Error: \(errorMessage)"
                }
                
                if let responseText = json["response"] as? String {
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
    
    // MARK: - Helper Methods
    
    private func buildContextualPrompt(for currentMessage: String) -> String {
        // Take the last 10 messages for context (excluding the current one we just added)
        let contextMessages = Array(conversationHistory.suffix(11).dropLast())
        
        if contextMessages.isEmpty {
            return currentMessage
        }
        
        // Build conversation context
        let context = contextMessages.map { message in
            let role = message.isUser ? "User" : "AI"
            return "\(role): \(message.content)"
        }.joined(separator: "\n")
        
        return """
        Previous conversation context:
        \(context)
        
        Current question: \(currentMessage)
        
        Please provide a helpful response that takes into account the conversation history.
        """
    }
    
    func clearConversation() {
        conversationHistory.removeAll()
        saveCurrentConversation()
    }
    
    private func loadCurrentConversation() {
        if let current = UserDefaults.standard.getCurrentConversation() {
            currentConversation = current
            conversationHistory = current.messages
        } else {
            // Create new conversation if none exists
            let newConversation = UserDefaults.standard.createNewConversation()
            currentConversation = newConversation
            conversationHistory = []
        }
    }
    
    func loadConversation(_ conversation: ChatConversation) {
        currentConversation = conversation
        conversationHistory = conversation.messages
        UserDefaults.standard.currentConversationId = conversation.id
    }
    
    private func saveCurrentConversation() {
        guard var conversation = currentConversation else { return }
        
        conversation.messages = conversationHistory
        conversation.lastModified = Date()
        
        // Auto-generate title from first user message if it's still "New Chat"
        if conversation.title == "New Chat" && !conversationHistory.isEmpty {
            conversation.generateTitle()
        }
        
        UserDefaults.standard.saveConversation(conversation)
        currentConversation = conversation
    }
    
    func createNewConversation(title: String = "New Chat") {
        let newConversation = UserDefaults.standard.createNewConversation(title: title)
        loadConversation(newConversation)
    }
    
    func updateConversationTitle(_ title: String) {
        guard var conversation = currentConversation else { return }
        conversation.title = title
        UserDefaults.standard.saveConversation(conversation)
        currentConversation = conversation
    }
    
    // MARK: - File Processing
    
    func processFiles(_ urls: [URL]) async -> String? {
        var processedContent: [String] = []
        var images: [String] = []
        
        for url in urls {
            let fileExtension = url.pathExtension.lowercased()
            
            if !supportedFileTypes.contains(fileExtension) {
                processedContent.append("⚠️ Unsupported file type: \(url.lastPathComponent)")
                continue
            }
            
            do {
                if isImageFile(fileExtension) {
                    if isVisionModel {
                        let imageData = try Data(contentsOf: url)
                        let base64Image = imageData.base64EncodedString()
                        images.append(base64Image)
                        processedContent.append("📷 Image: \(url.lastPathComponent)")
                    } else {
                        processedContent.append("⚠️ Image files require a vision model (llava, bakllava, etc.). Current model: \(selectedModel)")
                    }
                } else if isTextFile(fileExtension) {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let fileName = url.lastPathComponent
                    processedContent.append("📄 **\(fileName)**:\n```\(fileExtension)\n\(content)\n```")
                }
            } catch {
                processedContent.append("❌ Error reading \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        if processedContent.isEmpty {
            return nil
        }
        
        let finalPrompt = processedContent.joined(separator: "\n\n")
        
        // If we have images, use the vision-capable API
        if !images.isEmpty && isVisionModel {
            return await sendMessageWithImages(finalPrompt, images: images)
        } else {
            return await sendMessage(finalPrompt)
        }
    }
    
    private func isImageFile(_ fileExtension: String) -> Bool {
        return ["png", "jpg", "jpeg", "gif", "webp"].contains(fileExtension)
    }
    
    private func isTextFile(_ fileExtension: String) -> Bool {
        return ["txt", "md", "swift", "py", "js", "html", "css", "json", "xml"].contains(fileExtension)
    }
    
    private func sendMessageWithImages(_ prompt: String, images: [String]) async -> String {
        guard isConnected else { return "Error: Ollama is not connected" }
        
        // Prevent race condition by capturing the current conversation ID
        guard let originalConversationId = currentConversation?.id else {
            return "Error: No active conversation"
        }
        
        isGenerating = true
        generatingConversationId = originalConversationId
        defer { 
            isGenerating = false
            generatingConversationId = nil
        }
        
        let userMessage = ChatMessage(role: .user, content: prompt)
        conversationHistory.append(userMessage)
        saveCurrentConversation()
        
        do {
            let url = URL(string: "\(baseURL)/api/generate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "model": selectedModel,
                "prompt": prompt,
                "images": images,
                "stream": false
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await generateSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Vision API Response Status: \(httpResponse.statusCode)")
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorMessage = json["error"] as? String {
                    return "Error: \(errorMessage)"
                }
                
                if let responseText = json["response"] as? String {
                    // Ensure response goes to the original conversation
                    await saveResponseToConversation(responseText, conversationId: originalConversationId)
                    return responseText
                }
            }
            
        } catch {
            let errorMsg = error.localizedDescription
            if errorMsg.contains("timed out") {
                return "Error: Request timed out. Vision processing can take longer than text-only requests."
            } else if errorMsg.contains("Connection refused") {
                return "Error: Connection refused. Make sure Ollama is running with 'ollama serve'."
            }
            return "Error: \(errorMsg)"
        }
        
        return "Error: Failed to get response from vision model"
    }
    
    private func saveResponseToConversation(_ response: String, conversationId: UUID) async {
        // Get the conversation from UserDefaults to ensure we have the most up-to-date version
        guard var conversation = UserDefaults.standard.chatConversations.first(where: { $0.id == conversationId }) else { 
            return 
        }
        
        let assistantMessage = ChatMessage(role: .assistant, content: response)
        conversation.messages.append(assistantMessage)
        conversation.lastModified = Date()
        
        // Auto-generate title from first user message if it's still "New Chat"
        if conversation.title == "New Chat" && !conversation.messages.isEmpty {
            conversation.generateTitle()
        }
        
        // Save the conversation
        UserDefaults.standard.saveConversation(conversation)
        
        // If this is still the current conversation, update the local state
        if currentConversation?.id == conversationId {
            currentConversation = conversation
            conversationHistory = conversation.messages
        }
    }
    
    // MARK: - Model Management
    
    func getInstalledModels() async -> [OllamaModel] {
        guard isConnected else { return [] }
        
        do {
            let url = URL(string: "\(baseURL)/api/tags")!
            let (data, _) = try await quickSession.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                return models.compactMap { modelData in
                    guard let name = modelData["name"] as? String else { return nil }
                    
                    // Get additional model info
                    let size = (modelData["size"] as? Int64) ?? 0
                    let modifiedAt = modelData["modified_at"] as? String ?? ""
                    
                    return OllamaModel(
                        name: name,
                        size: size,
                        modifiedAt: modifiedAt
                    )
                }
            }
        } catch {
            print("Error fetching installed models: \(error)")
        }
        
        return []
    }
    
    func deleteModel(_ modelName: String) async -> Bool {
        guard isConnected else { return false }
        
        do {
            let url = URL(string: "\(baseURL)/api/delete")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "name": modelName
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (_, response) = try await quickSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("Error deleting model: \(error)")
        }
        
        return false
    }
    
    func downloadModel(_ modelName: String, onProgress: @escaping (String) -> Void) async -> Bool {
        guard isConnected else { 
            onProgress("Error: Ollama is not connected")
            return false
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/pull")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "name": modelName,
                "stream": true
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (bytes, _) = try await generateSession.bytes(for: request)
            
            for try await line in bytes.lines {
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    if let status = json["status"] as? String {
                        onProgress(status)
                    }
                    
                    if let completed = json["completed"] as? Int64,
                       let total = json["total"] as? Int64, total > 0 {
                        let percentage = Int((Double(completed) / Double(total)) * 100)
                        onProgress("Downloading... \(percentage)%")
                    }
                    
                    if let error = json["error"] as? String {
                        onProgress("Error: \(error)")
                        return false
                    }
                }
            }
            
            // Refresh the models list after successful download
            await loadAvailableModels()
            onProgress("Download completed successfully!")
            return true
            
        } catch {
            onProgress("Error: \(error.localizedDescription)")
            return false
        }
    }
    
    // Get system specifications for model recommendations
    func getSystemSpecs() -> SystemSpecs {
        var specs = SystemSpecs()
        
        // Get RAM information
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            specs.totalRAM = ProcessInfo.processInfo.physicalMemory
        }
        
        // Get CPU information
        #if arch(arm64)
        specs.architecture = "Apple Silicon"
        if let cpuBrand = getAppleSiliconChip() {
            specs.cpuModel = cpuBrand
        }
        #else
        specs.architecture = "Intel"
        specs.cpuModel = "Intel"
        #endif
        
        return specs
    }
    
    private func getAppleSiliconChip() -> String? {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelString = String(cString: model)
        
        // Map model identifiers to user-friendly names
        if modelString.contains("Mac14,3") { return "M2 Pro" }
        if modelString.contains("Mac14,5") { return "M2 Max" }
        if modelString.contains("Mac14,2") { return "M2" }
        if modelString.contains("Mac15,3") { return "M3 Pro" }
        if modelString.contains("Mac15,5") { return "M3 Max" }
        if modelString.contains("Mac15,1") { return "M3" }
        if modelString.contains("Mac16,1") { return "M4" }
        if modelString.contains("Mac16,3") { return "M4 Pro" }
        if modelString.contains("Mac16,5") { return "M4 Max" }
        
        // Fallback for M1 and other chips
        if modelString.contains("Mac") { return "Apple Silicon" }
        
        return nil
    }
    
    // Get recommended models based on system specs
    func getRecommendedModels(for specs: SystemSpecs) -> [RecommendedModel] {
        let ramGB = specs.totalRAM / (1024 * 1024 * 1024)
        var models: [RecommendedModel] = []
        
        // Always recommend lightweight models
        models.append(RecommendedModel(
            name: "llama3.2:1b",
            description: "Ultra-fast 1B model, perfect for quick tasks",
            size: "1.3GB",
            recommended: true,
            reason: "Excellent for all systems, very fast"
        ))
        
        models.append(RecommendedModel(
            name: "llama3.2:3b",
            description: "Balanced 3B model with good performance",
            size: "2.0GB", 
            recommended: ramGB >= 8,
            reason: ramGB >= 8 ? "Great balance of speed and quality" : "May be slow on 8GB systems"
        ))
        
        // 7B models for 8GB+ systems
        if ramGB >= 8 {
            models.append(RecommendedModel(
                name: "llama3.1:7b",
                description: "High-quality 7B model for general use",
                size: "4.7GB",
                recommended: ramGB >= 12,
                reason: ramGB >= 12 ? "Excellent quality for most tasks" : "Good quality, may use swap"
            ))
            
            models.append(RecommendedModel(
                name: "mistral:7b",
                description: "Efficient 7B model with great performance",
                size: "4.1GB",
                recommended: ramGB >= 12,
                reason: ramGB >= 12 ? "Very efficient and fast" : "Good option for 8GB systems"
            ))
        }
        
        // 9B+ models for 16GB+ systems
        if ramGB >= 16 {
            models.append(RecommendedModel(
                name: "gemma2:9b",
                description: "Google's 9B model with excellent capabilities",
                size: "5.4GB",
                recommended: true,
                reason: "Excellent for 16GB+ systems"
            ))
            
            models.append(RecommendedModel(
                name: "qwen2.5:14b",
                description: "Advanced 14B model with multilingual support",
                size: "8.7GB",
                recommended: ramGB >= 24,
                reason: ramGB >= 24 ? "Great for complex tasks" : "May be slower on 16GB"
            ))
        }
        
        // Large models for 32GB+ systems
        if ramGB >= 32 {
            models.append(RecommendedModel(
                name: "llama3.1:70b",
                description: "State-of-the-art 70B model for professional use",
                size: "40GB",
                recommended: ramGB >= 64,
                reason: ramGB >= 64 ? "Professional grade performance" : "May exceed memory limits"
            ))
        }
        
        // Specialized models
        models.append(RecommendedModel(
            name: "llava:7b", 
            description: "Vision-capable model for image analysis",
            size: "4.7GB",
            recommended: ramGB >= 12,
            reason: "Supports image understanding"
        ))
        
        models.append(RecommendedModel(
            name: "codegemma:7b",
            description: "Specialized coding model",
            size: "5.0GB", 
            recommended: ramGB >= 12,
            reason: "Optimized for code generation"
        ))
        
        return models.sorted { $0.recommended && !$1.recommended }
    }
}

// MARK: - Models

struct OllamaModel: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let size: Int64
    let modifiedAt: String
    
    init(name: String, size: Int64 = 0, modifiedAt: String = "") {
        self.name = name
        self.size = size
        self.modifiedAt = modifiedAt
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    // Computed property for human-readable size
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct SystemSpecs {
    var totalRAM: UInt64 = 0
    var architecture: String = "Unknown"
    var cpuModel: String = "Unknown"
    
    var formattedRAM: String {
        let ramGB = totalRAM / (1024 * 1024 * 1024)
        return "\(ramGB)GB"
    }
}

struct RecommendedModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let size: String
    let recommended: Bool
    let reason: String
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
    
    init(id: UUID, role: MessageRole, content: String, timestamp: Date) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    
    var isUser: Bool {
        return role == .user
    }
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
