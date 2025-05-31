import SwiftUI

struct AIAssistantView: View {
    @StateObject private var ollamaService = OllamaService()
    @State private var selectedTool: AITool = .chat
    @State private var showOllamaInstructions = false
    @State private var isStartingOllama = false
    
    var body: some View {
        Group {
            if ollamaService.isConnected {
                connectedView
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
                .onAppear {
                    NotificationCenter.default.post(name: .sheetPresented, object: nil)
                }
                .onDisappear {
                    NotificationCenter.default.post(name: .sheetDismissed, object: nil)
                }
        }
    }
    
    private var connectedView: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Model Selector & Status
            statusHeader
            
            // Tool Selector
            toolSelector
            
            // Tool Content
            toolContent
        }
        .padding(DesignSystem.Spacing.lg)
    }
    
    private var disconnectedView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Ollama Status
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.warning)
                
                Text("Ollama Not Running")
                    .font(DesignSystem.Typography.headline2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("AI Assistant requires Ollama to be running locally")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action Buttons
            VStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: {
                    showOllamaInstructions = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "info.circle.fill")
                        Text("Setup Instructions")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.BorderRadius.lg)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    startOllama()
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        if isStartingOllama {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("Start Ollama")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.success)
                    .cornerRadius(DesignSystem.BorderRadius.lg)
                }
                .buttonStyle(.plain)
                .disabled(isStartingOllama)
                
                Button(action: {
                    Task {
                        await ollamaService.checkConnection()
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        if ollamaService.isChecking {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check Connection")
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.BorderRadius.lg)
                }
                .buttonStyle(.plain)
                .disabled(ollamaService.isChecking)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var statusHeader: some View {
        HStack {
            // Connection Status
            HStack(spacing: DesignSystem.Spacing.xs) {
                Circle()
                    .fill(ollamaService.isGenerating ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                    .frame(width: 8, height: 8)
                    .scaleEffect(ollamaService.isGenerating ? 1.2 : 1.0)
                    .animation(
                        ollamaService.isGenerating ? 
                        DesignSystem.Animation.gentle.repeatForever(autoreverses: true) : 
                        DesignSystem.Animation.gentle,
                        value: ollamaService.isGenerating
                    )
                
                Text(ollamaService.isGenerating ? "Generating..." : "Connected")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(ollamaService.isGenerating ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
            }
            
            Spacer()
            
            // Model Selector
            if !ollamaService.availableModels.isEmpty {
                Menu {
                    ForEach(ollamaService.availableModels, id: \.self) { model in
                        Button(action: {
                            if !ollamaService.isGenerating {
                                ollamaService.selectedModel = model
                            }
                        }) {
                            HStack {
                                Text(model)
                                if model == ollamaService.selectedModel {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.success)
                                }
                            }
                        }
                        .disabled(ollamaService.isGenerating)
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(ollamaService.selectedModel)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ollamaService.isGenerating ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.textSecondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(ollamaService.isGenerating ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.textSecondary)
                    }
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .buttonStyle(.plain)
                .disabled(ollamaService.isGenerating)
            }
        }
    }
    
    private var toolSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(AITool.allCases, id: \.self) { tool in
                    AIToolButton(
                        tool: tool,
                        isSelected: selectedTool == tool
                    ) {
                        withAnimation(DesignSystem.Animation.gentle) {
                            selectedTool = tool
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
    }
    
    private var toolContent: some View {
        Group {
            switch selectedTool {
            case .chat:
                AIChatView(ollamaService: ollamaService)
            case .codeAssistant:
                CodeAssistantView(ollamaService: ollamaService)
            case .textProcessor:
                TextProcessorView(ollamaService: ollamaService)
            case .errorExplainer:
                ErrorExplainerView(ollamaService: ollamaService)
            case .quickPrompts:
                QuickPromptsView(ollamaService: ollamaService)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(DesignSystem.Animation.smooth, value: selectedTool)
    }
    
    // MARK: - Helper Functions
    
    private func startOllama() {
        isStartingOllama = true
        
        Task {
            do {
                // Try to launch Ollama.app from Applications folder
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                process.arguments = ["-a", "Ollama"]
                
                try process.run()
                process.waitUntilExit()
                
                // Wait a moment for Ollama to start up
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                
                // Check if Ollama is now running
                await ollamaService.checkConnection()
                
            } catch {
                print("Failed to start Ollama: \(error)")
                
                // Fallback: try the direct path approach
                do {
                    let fallbackProcess = Process()
                    fallbackProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    fallbackProcess.arguments = ["/Applications/Ollama.app"]
                    
                    try fallbackProcess.run()
                    fallbackProcess.waitUntilExit()
                    
                    // Wait for startup
                    try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                    await ollamaService.checkConnection()
                    
                } catch {
                    print("Fallback also failed: \(error)")
                }
            }
            
            isStartingOllama = false
        }
    }
}

// MARK: - Tool Button Component

struct AIToolButton: View {
    let tool: AITool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: tool.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(tool.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isSelected ? tool.color : DesignSystem.Colors.surface.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Tool Definitions

enum AITool: CaseIterable {
    case chat
    case codeAssistant
    case textProcessor
    case errorExplainer
    case quickPrompts
    
    var title: String {
        switch self {
        case .chat: return "Chat"
        case .codeAssistant: return "Code"
        case .textProcessor: return "Text"
        case .errorExplainer: return "Debug"
        case .quickPrompts: return "Quick"
        }
    }
    
    var icon: String {
        switch self {
        case .chat: return "message.fill"
        case .codeAssistant: return "chevron.left.forwardslash.chevron.right"
        case .textProcessor: return "doc.text.fill"
        case .errorExplainer: return "ladybug.fill"
        case .quickPrompts: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .chat: return DesignSystem.Colors.primary
        case .codeAssistant: return DesignSystem.Colors.success
        case .textProcessor: return DesignSystem.Colors.clipboard
        case .errorExplainer: return DesignSystem.Colors.error
        case .quickPrompts: return DesignSystem.Colors.warning
        }
    }
}

// MARK: - Ollama Instructions Sheet

struct OllamaInstructionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Setup Ollama")
                    .font(DesignSystem.Typography.headline1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.surface.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    Text("Follow these steps to get AI Assistant working:")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.top, DesignSystem.Spacing.md)
                    
                    // Steps
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        InstructionStep(
                            number: 1,
                            title: "Install Ollama",
                            description: "Visit ollama.ai and download Ollama for macOS",
                            action: "Open ollama.ai",
                            url: "https://ollama.ai"
                        )
                        
                        InstructionStep(
                            number: 2,
                            title: "Start Ollama",
                            description: "Run Ollama App from Launchpad or open Terminal and run: ollama serve",
                            action: "Copy Command",
                            copyText: "ollama serve"
                        )
                        
                        InstructionStep(
                            number: 3,
                            title: "Download a Model",
                            description: "Open Terminal and download a recommended model like Llama 3.2",
                            action: "Copy Command",
                            copyText: "ollama pull llama3.2:3b"
                        )
                        
                        InstructionStep(
                            number: 4,
                            title: "Verify Connection",
                            description: "Return to Dynamic Toolbox and check connection",
                            action: nil
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl))
        .shadow(
            color: DesignSystem.Shadows.xl.color,
            radius: DesignSystem.Shadows.xl.radius,
            x: DesignSystem.Shadows.xl.x,
            y: DesignSystem.Shadows.xl.y
        )
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    let action: String?
    var url: String?
    var copyText: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Step Number
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(DesignSystem.Colors.primary))
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if let action = action {
                    Button(action) {
                        if let url = url {
                            NSWorkspace.shared.open(URL(string: url)!)
                        } else if let copyText = copyText {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(copyText, forType: .string)
                        }
                    }
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(DesignSystem.Colors.surface.opacity(0.3))
        )
    }
} 
