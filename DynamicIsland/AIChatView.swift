import SwiftUI

struct AIChatView: View {
    @StateObject private var ollamaService = OllamaService()
    @State private var inputText = ""
    @State private var isDropTargeted = false
    @State private var draggedFiles: [URL] = []
    @State private var showingHistory = false
    
    var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !ollamaService.isGenerating && 
        ollamaService.isReadyToChat
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with conversation info and controls
            headerView
            
            // Chat history area with drop support
            chatHistoryView
            
            // Input area
            inputView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            Task {
                await ollamaService.checkConnection()
            }
        }
        .sheet(isPresented: $showingHistory) {
            ChatHistoryView(
                ollamaService: ollamaService,
                showingHistory: $showingHistory
            )
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // Current conversation info
                VStack(alignment: .leading, spacing: 2) {
                    Text(ollamaService.currentConversation?.title ?? "New Chat")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 4) {
                        Text("\(ollamaService.conversationHistory.count) messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if ollamaService.webSearchEnabled {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 2) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                Text("Web Search")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if ollamaService.webSearchService.isSearching {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 2) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Searching...")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 12) {
                    // Web search toggle
                    Button(action: {
                        ollamaService.toggleWebSearch()
                    }) {
                        Image(systemName: ollamaService.webSearchEnabled ? "globe.americas.fill" : "globe.americas")
                            .font(.system(size: 16))
                            .foregroundColor(ollamaService.webSearchEnabled ? .blue : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(ollamaService.webSearchEnabled ? "Disable web search" : "Enable web search")
                    
                    // New chat button
                    Button(action: {
                        ollamaService.createNewConversation()
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("New conversation")
                    
                    // History toggle button
                    Button(action: {
                        showingHistory.toggle()
                    }) {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Chat history")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Chat History View
    
    private var chatHistoryView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if ollamaService.conversationHistory.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(ollamaService.conversationHistory) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: ollamaService.conversationHistory.count) { newCount in
                if let lastMessage = ollamaService.conversationHistory.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .dropDestination(for: URL.self) { urls, location in
            handleDroppedFiles(urls)
            return true
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        }
        .overlay(alignment: .center) {
            if isDropTargeted {
                dropTargetOverlay
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("AI Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 4) {
                    if ollamaService.isConnectedButNoModels {
                        Text("No AI models available")
                            .font(.body)
                            .foregroundColor(.orange)
                        
                        Text("Download a model using: ollama pull llama3.2:3b")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Ask me anything or drag files here to analyze")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if ollamaService.webSearchEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                Text("Web search is enabled for current information")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            
            VStack(spacing: 8) {
                Text("Supported file types:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Images: PNG, JPG, GIF, WebP")
                    .font(.caption2)
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                
                Text("Text: TXT, MD, Swift, Python, JS, HTML, CSS, JSON, XML")
                    .font(.caption2)
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
    
    // MARK: - Drop Target Overlay
    
    private var dropTargetOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                )
                .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
            
            VStack(spacing: 8) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                if ollamaService.isVisionModel {
                    Text("Drop files to analyze with AI")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("Images and text files supported")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Drop text files to analyze")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("Switch to a vision model (llava, etc.) for image support")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(40)
    }
    
    // MARK: - Input View
    
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text input
                TextField("Ask me anything...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .disabled(ollamaService.isConnectedButNoModels)
                    .onSubmit {
                        sendMessage()
                    }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(canSendMessage ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canSendMessage)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty && !ollamaService.isGenerating else { return }
        
        inputText = ""
        
        Task {
            await ollamaService.sendStreamingMessage(message) { response in
                // Handle streaming response if needed
            }
        }
    }
    
    private func handleDroppedFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        draggedFiles = urls
        
        Task {
            if let response = await ollamaService.processFiles(urls) {
                // Files processed, response will be added to conversation
                print("Files processed: \(response)")
            }
        }
    }
}

// MARK: - Message View

struct MessageView: View {
    let message: ChatMessage
    @State private var isHovered = false
    @State private var showCopiedFeedback = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(message.role == .user ? Color.blue : Color.green)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: message.role == .user ? "person.fill" : "brain.head.profile")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                )
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.role.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Copy button for AI responses
                    if message.role == .assistant && (isHovered || showCopiedFeedback) {
                        Button(action: copyMessage) {
                            HStack(spacing: 4) {
                                Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 10, weight: .medium))
                                Text(showCopiedFeedback ? "Copied" : "Copy")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(showCopiedFeedback ? .green : .blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(showCopiedFeedback ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
                
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 40)
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func copyMessage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }
}

#Preview {
    AIChatView()
        .frame(width: 600, height: 500)
} 