import SwiftUI

struct AIChatView: View {
    @ObservedObject var ollamaService: OllamaService
    @State private var messageText = ""
    @State private var isProcessing = false
    @State private var currentResponse = ""
    @State private var showingResponse = false
    @State private var showingHistory = false
    @State private var isDropTargeted = false
    @State private var draggedFiles: [URL] = []
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Header with controls
            headerView
            
            if showingHistory {
                // Chat History View
                ChatHistoryView(ollamaService: ollamaService, showingHistory: $showingHistory)
            } else {
                // Regular Chat View
                VStack(spacing: DesignSystem.Spacing.sm) {
                    // Chat History
                    chatHistory
                    
                    // Input Area
                    inputArea
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // Conversation title (if available)
            VStack(alignment: .leading, spacing: 2) {
                if let conversation = ollamaService.currentConversation {
                    Text(conversation.title)
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(conversation.messageCount) messages")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                } else {
                    Text("AI Assistant")
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            
            Spacer()
            
            // History toggle button
            Button(action: { showingHistory.toggle() }) {
                Image(systemName: showingHistory ? "message" : "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
            
            // New chat button
            if !showingHistory {
                Button(action: createNewChat) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }
    
    private var chatHistory: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                if ollamaService.conversationHistory.isEmpty {
                    emptyState
                } else {
                    ForEach(ollamaService.conversationHistory) { message in
                        ChatMessageView(message: message)
                    }
                    
                    // Current streaming response
                    if showingResponse && !currentResponse.isEmpty {
                        ChatMessageView(
                            message: ChatMessage(
                                role: .assistant,
                                content: currentResponse
                            ),
                            isStreaming: true
                        )
                    }
                }
                
                // Drag and drop overlay when files are being dragged
                if isDropTargeted {
                    dropTargetOverlay
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(isDropTargeted ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surface.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(isDropTargeted ? DesignSystem.Colors.primary.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .dropDestination(for: URL.self) { urls, location in
            handleDroppedFiles(urls)
            return true
        } isTargeted: { isTargeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = isTargeted
            }
        }
    }
    
    private var dropTargetOverlay: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: ollamaService.isVisionModel ? "photo.badge.plus" : "doc.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Drop files here")
                    .font(DesignSystem.Typography.headline3)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                if ollamaService.isVisionModel {
                    Text("Images & text files supported")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                } else {
                    Text("Text files supported • Images need vision model")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(DesignSystem.Colors.primary.opacity(0.05))
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "message.circle")
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("Start a conversation")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // File support info
            VStack(spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    if ollamaService.isVisionModel {
                        Text("Drop images or files to analyze")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    } else {
                        Text("Drop text files to analyze")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                if !ollamaService.isVisionModel {
                    Text("Use llava or bakllava for image support")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            
            // Quick starter prompts
            VStack(spacing: DesignSystem.Spacing.xs) {
                QuickPromptButton(
                    text: "Explain Swift concurrency",
                    action: { messageText = "Explain Swift concurrency" }
                )
                
                QuickPromptButton(
                    text: "Write a Python function",
                    action: { messageText = "Write a Python function to calculate factorial" }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.lg)
    }
    
    private var inputArea: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            TextField("Ask me anything...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(DesignSystem.Typography.body)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(DesignSystem.Colors.surface.opacity(0.5))
                )
                .disabled(isProcessing)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Group {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        DesignSystem.Colors.textSecondary : DesignSystem.Colors.primary
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isProcessing else { return }
        
        messageText = ""
        isProcessing = true
        showingResponse = true
        currentResponse = ""
        
        Task {
            await ollamaService.sendStreamingMessage(message) { response in
                currentResponse = response
            }
            
            isProcessing = false
            showingResponse = false
            currentResponse = ""
        }
    }
    
    private func createNewChat() {
        ollamaService.createNewConversation()
    }
    
    private func handleDroppedFiles(_ urls: [URL]) {
        draggedFiles = urls
        
        guard !isProcessing else { return }
        
        isProcessing = true
        showingResponse = true
        currentResponse = "Processing files..."
        
        Task {
            if let response = await ollamaService.processFiles(urls) {
                currentResponse = response
            } else {
                currentResponse = "No supported files found or failed to process files."
            }
            
            // Small delay to show the final response
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            isProcessing = false
            showingResponse = false
            currentResponse = ""
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    var isStreaming: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // Avatar
            Circle()
                .fill(message.role == .user ? DesignSystem.Colors.primary : DesignSystem.Colors.success)
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: message.role == .user ? "person.fill" : "brain.head.profile")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                )
            
            // Message Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(message.role.displayName)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(message.content)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .textSelection(.enabled)
                
                if isStreaming {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(DesignSystem.Colors.textSecondary)
                                .frame(width: 4, height: 4)
                                .scaleEffect(1.0)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: isStreaming
                                )
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct QuickPromptButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
} 