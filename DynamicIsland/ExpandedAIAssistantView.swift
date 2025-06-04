import SwiftUI

struct ExpandedAIAssistantView: View {
    @StateObject private var ollamaService = OllamaService()
    @State private var selectedTool: AITool = .chat
    @State private var showOllamaInstructions = false
    @State private var isStartingOllama = false
    @State private var chatInput: String = ""
    @State private var showingHistory = false
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
        HStack(spacing: 0) {
            // Chat history sidebar (only shown in chat mode)
            if selectedTool == .chat && showingHistory {
                chatHistorySidebar
                    .frame(width: 350)
                    .transition(.move(edge: .leading))
                
                Divider()
                    .background(DesignSystem.Colors.border)
            }
            
            // Main content
            VStack(spacing: 0) {
                // Header with model selector and tools
                headerSection
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Main chat interface
                chatInterface
            }
        }
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.3), value: showingHistory)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Title and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if selectedTool == .chat {
                        Text(ollamaService.currentConversation?.title ?? "New Chat")
                            .font(DesignSystem.Typography.headline1)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    } else {
                        Text("AI Assistant")
                            .font(DesignSystem.Typography.headline1)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: 8, height: 8)
                        
                        if selectedTool == .chat {
                            Text("Connected • \(ollamaService.currentModel?.name ?? "No model") • \(ollamaService.conversationHistory.count) messages")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        } else {
                            Text("Connected • \(ollamaService.currentModel?.name ?? "No model")")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Chat history controls (only for chat mode)
                    if selectedTool == .chat {
                        chatControls
                    }
                    
                    // Model selector
                    modelSelector
                }
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
                        // Hide history sidebar when switching away from chat
                        if tool != .chat {
                            showingHistory = false
                        }
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
            
            // Input area - only show for chat
            if selectedTool == .chat {
                inputSection
            }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - Chat Controls
    
    private var chatControls: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // History toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingHistory.toggle()
                }
            }) {
                Image(systemName: showingHistory ? "sidebar.left" : "clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(showingHistory ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(showingHistory ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surface)
                    )
            }
            .buttonStyle(.plain)
            .help(showingHistory ? "Hide history" : "Show chat history")
            
            // New conversation
            Button(action: {
                ollamaService.createNewConversation()
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.surface)
                    )
            }
            .buttonStyle(.plain)
            .help("New conversation")
            
            // Web search toggle
            Button(action: {
                ollamaService.toggleWebSearch()
            }) {
                Image(systemName: ollamaService.webSearchEnabled ? "globe.americas.fill" : "globe.americas")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ollamaService.webSearchEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(ollamaService.webSearchEnabled ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surface)
                    )
            }
            .buttonStyle(.plain)
            .help(ollamaService.webSearchEnabled ? "Disable web search" : "Enable web search")
        }
    }
    
    // MARK: - Chat History Sidebar
    
    private var chatHistorySidebar: some View {
        VStack(spacing: 0) {
            // Sidebar header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat History")
                        .font(DesignSystem.Typography.headline2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(UserDefaults.standard.chatConversations.count) conversations")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    ollamaService.createNewConversation()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Search bar
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .font(.system(size: 14, weight: .medium))
                
                TextField("Search conversations...", text: .constant(""))
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            
            // Conversations list
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(UserDefaults.standard.chatConversations) { conversation in
                        ExpandedConversationRowView(
                            conversation: conversation,
                            isSelected: UserDefaults.standard.currentConversationId == conversation.id,
                            onSelect: { selectConversation(conversation) },
                            onDelete: { deleteConversation(conversation) }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            
            Spacer()
            
            // Bottom actions
            VStack(spacing: DesignSystem.Spacing.sm) {
                Divider()
                    .background(DesignSystem.Colors.border)
                
                HStack {
                    Button("Clear All") {
                        UserDefaults.standard.clearAllConversations()
                        ollamaService.createNewConversation()
                    }
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .fill(DesignSystem.Colors.error.opacity(0.1))
                    )
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Chat History Actions
    
    private func selectConversation(_ conversation: ChatConversation) {
        UserDefaults.standard.currentConversationId = conversation.id
        ollamaService.loadConversation(conversation)
    }
    
    private func deleteConversation(_ conversation: ChatConversation) {
        UserDefaults.standard.deleteConversation(id: conversation.id)
        
        // If we deleted the current conversation, create a new one
        if UserDefaults.standard.currentConversationId == conversation.id {
            ollamaService.createNewConversation()
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
    @State private var codeInput: String = ""
    @State private var codeOutput: String = ""
    @State private var selectedTask: CodeTask = .review
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Task selector
            HStack {
                Text("Code Task:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Task", selection: $selectedTask) {
                    ForEach(CodeTask.allCases, id: \.self) { task in
                        Text(task.rawValue).tag(task)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                Spacer()
                
                Button("Process Code") {
                    processCode()
                }
                .buttonStyle_custom(.primary)
                .disabled(codeInput.isEmpty || isProcessing)
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Code input
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Code Input")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $codeInput)
                        .font(.system(size: 14, design: .monospaced))
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // AI output
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("AI Analysis")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Spacer()
                        
                        if !codeOutput.isEmpty {
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(codeOutput, forType: .string)
                            }
                            .buttonStyle_custom(.ghost)
                        }
                    }
                    
                    ScrollView {
                        Text(codeOutput.isEmpty ? "AI analysis will appear here..." : codeOutput)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(codeOutput.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.lg)
                            .textSelection(.enabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private func processCode() {
        guard !codeInput.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            let result = await ollamaService.processCode(code: codeInput, task: selectedTask)
            await MainActor.run {
                codeOutput = result
                isProcessing = false
            }
        }
    }
}

struct ExpandedTextProcessorView: View {
    let ollamaService: OllamaService
    @State private var textInput: String = ""
    @State private var textOutput: String = ""
    @State private var selectedTask: TextTask = .summarize
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Task selector
            HStack {
                Text("Text Task:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Task", selection: $selectedTask) {
                    ForEach(TextTask.allCases, id: \.self) { task in
                        Text(task.rawValue).tag(task)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                Spacer()
                
                Button("Process Text") {
                    processText()
                }
                .buttonStyle_custom(.primary)
                .disabled(textInput.isEmpty || isProcessing)
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Text input
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Text Input")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $textInput)
                        .font(DesignSystem.Typography.body)
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // AI output
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Processed Text")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Spacer()
                        
                        if !textOutput.isEmpty {
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(textOutput, forType: .string)
                            }
                            .buttonStyle_custom(.ghost)
                        }
                    }
                    
                    ScrollView {
                        Text(textOutput.isEmpty ? "Processed text will appear here..." : textOutput)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(textOutput.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.lg)
                            .textSelection(.enabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private func processText() {
        guard !textInput.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            let result = await ollamaService.processText(text: textInput, task: selectedTask)
            await MainActor.run {
                textOutput = result
                isProcessing = false
            }
        }
    }
}

struct ExpandedQuickPromptsView: View {
    let ollamaService: OllamaService
    @State private var selectedPrompt: String = ""
    @State private var customPrompt: String = ""
    @State private var promptResult: String = ""
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    
    private let quickPrompts = [
        "Explain this in simple terms",
        "What are the pros and cons?",
        "Give me 5 key takeaways",
        "How can I improve this?",
        "What are the next steps?",
        "Summarize in 3 sentences",
        "What's the main problem here?",
        "Suggest alternatives",
        "Break this down step by step",
        "What questions should I ask?"
    ]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Quick prompts grid
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Quick Prompts")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button(prompt) {
                            selectedPrompt = prompt
                            executePrompt(prompt)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .fill(selectedPrompt == prompt ? DesignSystem.Colors.primary.opacity(0.2) : DesignSystem.Colors.surface)
                        )
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Custom prompt input
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Custom Prompt")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack {
                    TextField("Enter your custom prompt...", text: $customPrompt)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .onSubmit {
                            executeCustomPrompt()
                        }
                    
                    Button("Send") {
                        executeCustomPrompt()
                    }
                    .buttonStyle_custom(.primary)
                    .disabled(customPrompt.isEmpty || isProcessing)
                }
            }
            
            // Result area
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("AI Response")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Spacer()
                    
                    if !promptResult.isEmpty {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(promptResult, forType: .string)
                        }
                        .buttonStyle_custom(.ghost)
                        
                        Button("Clear") {
                            promptResult = ""
                            selectedPrompt = ""
                        }
                        .buttonStyle_custom(.ghost)
                    }
                }
                
                ScrollView {
                    Text(promptResult.isEmpty ? "AI response will appear here..." : promptResult)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(promptResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(DesignSystem.Spacing.lg)
                        .textSelection(.enabled)
                }
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                )
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private func executePrompt(_ prompt: String) {
        isProcessing = true
        
        Task {
            let result = await ollamaService.executeQuickPrompt(prompt)
            await MainActor.run {
                promptResult = result
                isProcessing = false
            }
        }
    }
    
    private func executeCustomPrompt() {
        guard !customPrompt.isEmpty else { return }
        
        selectedPrompt = customPrompt
        executePrompt(customPrompt)
        customPrompt = ""
    }
}

struct ExpandedErrorExplainerView: View {
    let ollamaService: OllamaService
    @State private var errorInput: String = ""
    @State private var errorExplanation: String = ""
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Instructions
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Error Explainer")
                    .font(DesignSystem.Typography.headline2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Paste your error message, stack trace, or error log below for AI-powered analysis and solutions.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Error input
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Error Details")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        Button("Analyze Error") {
                            analyzeError()
                        }
                        .buttonStyle_custom(.primary)
                        .disabled(errorInput.isEmpty || isProcessing)
                    }
                    
                    TextEditor(text: $errorInput)
                        .font(.system(size: 14, design: .monospaced))
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // AI explanation
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("AI Analysis & Solutions")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Spacer()
                        
                        if !errorExplanation.isEmpty {
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(errorExplanation, forType: .string)
                            }
                            .buttonStyle_custom(.ghost)
                        }
                    }
                    
                    ScrollView {
                        Text(errorExplanation.isEmpty ? "Error analysis and solutions will appear here..." : errorExplanation)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(errorExplanation.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.lg)
                            .textSelection(.enabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private func analyzeError() {
        guard !errorInput.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            let result = await ollamaService.explainError(error: errorInput)
            await MainActor.run {
                errorExplanation = result
                isProcessing = false
            }
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

// MARK: - Expanded Conversation Row View

struct ExpandedConversationRowView: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Selection indicator
            Circle()
                .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
                .shadow(color: isSelected ? DesignSystem.Colors.primary.opacity(0.3) : .clear, radius: 4)
            
            // Conversation content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text(conversation.title)
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    Text("\(conversation.messageCount)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(DesignSystem.Colors.surface)
                        )
                }
                
                Text(conversation.preview)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(conversation.formattedDate)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Spacer()
                    
                    if isHovered {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.error)
                                .padding(4)
                                .background(
                                    Circle()
                                        .fill(DesignSystem.Colors.error.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : 
                     (isHovered ? DesignSystem.Colors.surface.opacity(0.5) : DesignSystem.Colors.surface.opacity(0.3)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .stroke(isSelected ? DesignSystem.Colors.primary.opacity(0.4) : 
                       (isHovered ? DesignSystem.Colors.border.opacity(0.8) : DesignSystem.Colors.border.opacity(0.3)), 
                       lineWidth: isSelected ? 1.5 : 0.5)
        )
        .shadow(
            color: isSelected ? DesignSystem.Colors.primary.opacity(0.1) : .clear,
            radius: isSelected ? 4 : 0,
            x: 0,
            y: isSelected ? 2 : 0
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
} 