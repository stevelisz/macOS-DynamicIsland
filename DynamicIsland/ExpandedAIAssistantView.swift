import SwiftUI

struct ExpandedAIAssistantView: View {
    @StateObject private var ollamaService = OllamaService()
    @State private var selectedTool: AITool = .chat
    @State private var showOllamaInstructions = false
    @State private var isStartingOllama = false
    @State private var chatInput: String = ""
    @FocusState private var isChatInputFocused: Bool
    
    var body: some View {
        Group {
            if ollamaService.isConnected {
                if ollamaService.isConnectedButNoModels {
                    noModelsView
                } else {
                    connectedView
                }
            } else {
                disconnectedView
            }
        }
        .onAppear {
            Task {
                await ollamaService.checkConnection()
            }
        }
        .sheet(isPresented: $showOllamaInstructions) {
            OllamaInstructionsSheet()
                .interactiveDismissDisabled()
        }
    }
    
    // MARK: - Connected View
    
    private var connectedView: some View {
        VStack(spacing: 0) {
            // Header with model selector and tools
            headerSection
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Main chat interface
            chatInterface
        }
        .background(Color.clear)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Title and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Assistant")
                        .font(DesignSystem.Typography.headline1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: 8, height: 8)
                        Text("Connected • \(ollamaService.currentModel?.name ?? "No model")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Model selector
                modelSelector
            }
            
            // Tool selector
            toolSelector
        }
        .padding(.horizontal, DesignSystem.Spacing.xxl)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    private var modelSelector: some View {
        Menu {
            ForEach(ollamaService.availableModels, id: \.name) { model in
                Button(action: {
                    ollamaService.currentModel = model
                }) {
                    HStack {
                        Text(model.name)
                        if model.name == ollamaService.currentModel?.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Refresh Models") {
                Task {
                    await ollamaService.loadModels()
                }
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .medium))
                Text(ollamaService.currentModel?.name ?? "Select Model")
                    .font(DesignSystem.Typography.captionMedium)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var toolSelector: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(AITool.allCases, id: \.self) { tool in
                Button(action: {
                    withAnimation(DesignSystem.Animation.gentle) {
                        selectedTool = tool
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(tool.displayName)
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(selectedTool == tool ? .white : tool.color)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(selectedTool == tool ? tool.color : tool.color.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Chat Interface
    
    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.lg) {
                        if selectedTool == .chat {
                            chatMessages
                        } else {
                            toolSpecificContent
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
                    .padding(.vertical, DesignSystem.Spacing.xl)
                }
                .onChange(of: ollamaService.messages.count) { _, _ in
                    if let lastMessage = ollamaService.messages.last {
                        withAnimation(DesignSystem.Animation.smooth) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            inputSection
        }
    }
    
    private var chatMessages: some View {
        ForEach(ollamaService.messages, id: \.id) { message in
            ExpandedChatMessage(message: message)
                .id(message.id)
        }
    }
    
    private var toolSpecificContent: some View {
        Group {
            switch selectedTool {
            case .chat:
                EmptyView()
            case .codeAssistant:
                ExpandedCodeReviewView(ollamaService: ollamaService)
            case .textProcessor:
                ExpandedTextProcessorView(ollamaService: ollamaService)
            case .quickPrompts:
                ExpandedQuickPromptsView(ollamaService: ollamaService)
            case .errorExplainer:
                ExpandedErrorExplainerView(ollamaService: ollamaService)
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Divider()
                .background(DesignSystem.Colors.border)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                // Input field
                HStack(spacing: DesignSystem.Spacing.sm) {
                    TextField("Type your message...", text: $chatInput, axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .textFieldStyle(.plain)
                        .focused($isChatInputFocused)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    if !chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                                .stroke(isChatInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                )
                
                // Action buttons
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Button(action: clearChat) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.error)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.error.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: exportChat) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.surface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Disconnected State
    
    private var disconnectedView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.warning)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Ollama Not Running")
                        .font(DesignSystem.Typography.headline1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("AI Assistant requires Ollama to be running locally")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Action buttons
            VStack(spacing: DesignSystem.Spacing.md) {
                Button(action: {
                    showOllamaInstructions = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                        Text("Setup Instructions")
                            .font(DesignSystem.Typography.bodySemibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .frame(height: 44)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.BorderRadius.xl)
                }
                .buttonStyle(.plain)
                
                Button(action: startOllama) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isStartingOllama {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("Start Ollama")
                            .font(DesignSystem.Typography.bodySemibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .frame(height: 44)
                    .background(DesignSystem.Colors.success)
                    .cornerRadius(DesignSystem.BorderRadius.xl)
                }
                .buttonStyle(.plain)
                .disabled(isStartingOllama)
                
                Button(action: {
                    Task {
                        await ollamaService.checkConnection()
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if ollamaService.isChecking {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check Connection")
                            .font(DesignSystem.Typography.bodySemibold)
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: 300)
                    .frame(height: 44)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.BorderRadius.xl)
                }
                .buttonStyle(.plain)
                .disabled(ollamaService.isChecking)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DesignSystem.Spacing.xxl)
    }
    
    // MARK: - No Models State
    
    private var noModelsView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.warning)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("No AI Models Available")
                        .font(DesignSystem.Typography.headline1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Ollama is running, but no AI models are installed")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Installation instructions
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("To install a model, run in Terminal:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("ollama pull llama3.2:3b")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                    )
            }
            .frame(maxWidth: 400)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DesignSystem.Spacing.xxl)
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let message = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        chatInput = ""
        
        Task {
            await ollamaService.sendMessage(message)
        }
    }
    
    private func clearChat() {
        ollamaService.clearMessages()
    }
    
    private func exportChat() {
        let messages = ollamaService.messages.map { message in
            "\(message.isUser ? "User" : "Assistant"): \(message.content)"
        }.joined(separator: "\n\n")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(messages, forType: .string)
    }
    
    private func startOllama() {
        isStartingOllama = true
        
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Terminal", "--args", "ollama", "serve"]
        
        do {
            try task.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                Task {
                    await ollamaService.checkConnection()
                    isStartingOllama = false
                }
            }
        } catch {
            isStartingOllama = false
        }
    }
}

// MARK: - Expanded Chat Message

struct ExpandedChatMessage: View {
    let message: ChatMessage
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            if message.isUser {
                Spacer()
            }
            
            // Avatar
            Circle()
                .fill(message.isUser ? DesignSystem.Colors.primary : DesignSystem.Colors.ai)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: message.isUser ? "person.fill" : "brain.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
            
            // Message content
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: DesignSystem.Spacing.xs) {
                Text(message.content)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.lg)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                            } else {
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                                    .fill(DesignSystem.Colors.surface.opacity(0.8))
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl))
                            }
                        }
                    )
                    .frame(maxWidth: 400, alignment: message.isUser ? .trailing : .leading)
                
                // Copy button (shown on hover)
                if isHovered {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.content, forType: .string)
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10, weight: .medium))
                            Text("Copy")
                                .font(DesignSystem.Typography.micro)
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .onHover { isHovered = $0 }
        .animation(DesignSystem.Animation.gentle, value: isHovered)
    }
}

// MARK: - Tool-specific Expanded Views

struct ExpandedCodeReviewView: View {
    let ollamaService: OllamaService
    
    var body: some View {
        VStack {
            Text("Code Review - Expanded View")
                .font(DesignSystem.Typography.headline2)
            // Add specific code review UI here
        }
    }
}

struct ExpandedTextProcessorView: View {
    let ollamaService: OllamaService
    
    var body: some View {
        VStack {
            Text("Text Processor - Expanded View")
                .font(DesignSystem.Typography.headline2)
            // Add specific text processor UI here
        }
    }
}

struct ExpandedQuickPromptsView: View {
    let ollamaService: OllamaService
    
    var body: some View {
        VStack {
            Text("Quick Prompts - Expanded View")
                .font(DesignSystem.Typography.headline2)
            // Add specific quick prompts UI here
        }
    }
}

struct ExpandedErrorExplainerView: View {
    let ollamaService: OllamaService
    
    var body: some View {
        VStack {
            Text("Error Explainer - Expanded View")
                .font(DesignSystem.Typography.headline2)
            // Add specific error explainer UI here
        }
    }
}

// MARK: - AITool Extension

extension AITool {
    var displayName: String {
        switch self {
        case .chat: return "Chat"
        case .codeAssistant: return "Code Assistant"
        case .textProcessor: return "Text Processor"
        case .errorExplainer: return "Error Explainer"
        case .quickPrompts: return "Quick Prompts"
        }
    }
} 