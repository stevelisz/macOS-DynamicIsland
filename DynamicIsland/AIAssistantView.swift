import SwiftUI

struct AIAssistantView: View {
    @StateObject private var ollamaService = OllamaService()
    @State private var selectedTool: AITool = .chat
    @State private var showOllamaInstructions = false
    @State private var isStartingOllama = false
    
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
                .onAppear {
                    NotificationCenter.default.post(name: .sheetPresented, object: nil)
                }
                .onDisappear {
                    NotificationCenter.default.post(name: .sheetDismissed, object: nil)
                }
        }
    }
    
    private var connectedView: some View {
        VStack(spacing: 0) {
            // Model Selector & Status
            VStack(spacing: DesignSystem.Spacing.sm) {
                statusHeader
                
                // Tool Selector
                toolSelector
            }
            .padding(DesignSystem.Spacing.lg)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Tool Content - takes remaining space
            toolContent
        }
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
                            .frame(width: 16, height: 16)
                        Text("Setup Instructions")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.BorderRadius.lg)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    startOllama()
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Group {
                            if isStartingOllama {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.fill")
                            }
                        }
                        .frame(width: 16, height: 16)
                        
                        Text("Start Ollama")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
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
                        Group {
                            if ollamaService.isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .frame(width: 16, height: 16)
                        
                        Text("Check Connection")
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
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
    
    private var noModelsView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // No Models Status
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.warning)
                
                Text("No AI Models Available")
                    .font(DesignSystem.Typography.headline2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Ollama is running, but no AI models are installed")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Model Download Instructions
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Download a model:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("1.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text("Open Terminal")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("2.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text("Run: ")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text("ollama pull llama3.2:3b")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("3.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text("Wait for download to complete (~2GB)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.leading, DesignSystem.Spacing.sm)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.BorderRadius.lg)
            
            // Alternative Models
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Other recommended models:")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("• llama3.2:1b (smaller, faster)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    Text("• qwen2.5:3b (good performance)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    Text("• llava:7b (with vision support)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            
            // Action Buttons
            VStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: {
                    // Copy command to clipboard
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString("ollama pull llama3.2:3b", forType: .string)
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "doc.on.clipboard")
                            .frame(width: 16, height: 16)
                        Text("Copy Command")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.BorderRadius.lg)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    // Open Terminal app using the proper macOS method
                    NSWorkspace.shared.launchApplication("Terminal")
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "terminal")
                            .frame(width: 16, height: 16)
                        Text("Open Terminal")
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.BorderRadius.lg)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    Task {
                        await ollamaService.checkConnection()
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Group {
                            if ollamaService.isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .frame(width: 16, height: 16)
                        
                        Text("Refresh Models")
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
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
                    ForEach(ollamaService.availableModels, id: \.name) { model in
                        Button(action: {
                            if !ollamaService.isGenerating {
                                ollamaService.selectedModel = model.name
                            }
                        }) {
                            HStack {
                                Text(model.name)
                                if model.name == ollamaService.selectedModel {
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
                AIChatView()
            case .codeAssistant:
                CodeAssistantView(ollamaService: ollamaService)
            case .textProcessor:
                TextProcessorView(ollamaService: ollamaService)
            case .manageModels:
                CompactModelManagerView(ollamaService: ollamaService)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
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
            .frame(width: 50)
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
    case manageModels
    
    var title: String {
        switch self {
        case .chat: return "Chat"
        case .codeAssistant: return "Code"
        case .textProcessor: return "Text"
        case .manageModels: return "Models"
        }
    }
    
    var displayName: String {
        switch self {
        case .chat: return "Chat"
        case .codeAssistant: return "Code Assistant"
        case .textProcessor: return "Text Processor"
        case .manageModels: return "Manage Models"
        }
    }
    
    var icon: String {
        switch self {
        case .chat: return "message.fill"
        case .codeAssistant: return "chevron.left.forwardslash.chevron.right"
        case .textProcessor: return "doc.text.fill"
        case .manageModels: return "square.and.arrow.down"
        }
    }
    
    var color: Color {
        switch self {
        case .chat: return DesignSystem.Colors.primary
        case .codeAssistant: return DesignSystem.Colors.success
        case .textProcessor: return DesignSystem.Colors.clipboard
        case .manageModels: return DesignSystem.Colors.ai
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

// MARK: - Compact Model Manager View

struct CompactModelManagerView: View {
    @ObservedObject var ollamaService: OllamaService
    @State private var installedModels: [OllamaModel] = []
    @State private var recommendedModels: [RecommendedModel] = []
    @State private var isLoading = false
    @State private var systemSpecs = SystemSpecs()
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("Model Manager")
                    .font(DesignSystem.Typography.headline3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    loadModels()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.md)
            
            if isLoading {
                ProgressView("Loading models...")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.sm) {
                        // Installed Models Section
                        if !installedModels.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Installed Models")
                                    .font(DesignSystem.Typography.captionSemibold)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                
                                ForEach(installedModels) { model in
                                    CompactModelRow(
                                        model: model,
                                        status: .installed,
                                        onAction: {
                                            deleteModel(model.name)
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Recommended Models Section
                        if !recommendedModels.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Recommended for your Mac")
                                    .font(DesignSystem.Typography.captionSemibold)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                    .padding(.top, DesignSystem.Spacing.md)
                                
                                ForEach(recommendedModels, id: \.name) { model in
                                    let isInstalled = installedModels.contains { $0.name == model.name }
                                    let isDownloading = ollamaService.downloadingModels.contains(model.name)
                                    let progress = ollamaService.downloadProgress[model.name]
                                    
                                    CompactRecommendedModelRow(
                                        model: model,
                                        isInstalled: isInstalled,
                                        isDownloading: isDownloading,
                                        progress: progress,
                                        onDownload: {
                                            downloadModel(model.name)
                                        },
                                        onCancel: {
                                            ollamaService.cancelModelDownload(model.name)
                                        },
                                        onClearProgress: {
                                            ollamaService.clearDownloadProgress(model.name)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.lg)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadModels()
        }
    }
    
    private func loadModels() {
        isLoading = true
        
        Task {
            do {
                systemSpecs = ollamaService.getSystemSpecs()
                
                async let installed = ollamaService.getInstalledModels()
                let recommended = ollamaService.getRecommendedModels(for: systemSpecs)
                
                installedModels = try await installed
                recommendedModels = recommended
                
            } catch {
                print("Error loading models: \(error)")
            }
            
            isLoading = false
        }
    }
    
    private func downloadModel(_ modelName: String) {
        Task {
            let success = await ollamaService.downloadModel(modelName) { progress in
                // Progress is automatically handled by the shared state in OllamaService
            }
            
            if success {
                // Refresh models after download
                loadModels()
            }
        }
    }
    
    private func deleteModel(_ modelName: String) {
        Task {
            do {
                try await ollamaService.deleteModel(modelName)
                loadModels() // Refresh the list
            } catch {
                print("Error deleting model: \(error)")
            }
        }
    }
}

// MARK: - Compact Model Row Views

struct CompactModelRow: View {
    let model: OllamaModel
    let status: ModelStatus
    let onAction: () -> Void
    @State private var isHovered = false
    
    enum ModelStatus {
        case installed
        case downloading(String)
        case available
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Model info
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(model.formattedSize)
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            Spacer()
            
            // Status and action
            switch status {
            case .installed:
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Installed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    if isHovered {
                        Button(action: onAction) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .downloading(let progress):
                Text(progress)
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.Colors.warning)
            case .available:
                Button(action: onAction) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .fill(isHovered ? DesignSystem.Colors.surface.opacity(0.5) : DesignSystem.Colors.surface.opacity(0.2))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct CompactRecommendedModelRow: View {
    let model: RecommendedModel
    let isInstalled: Bool
    let isDownloading: Bool
    let progress: String?
    let onDownload: () -> Void
    let onCancel: (() -> Void)?
    let onClearProgress: (() -> Void)?
    
    init(model: RecommendedModel, isInstalled: Bool, isDownloading: Bool, progress: String?, onDownload: @escaping () -> Void, onCancel: (() -> Void)? = nil, onClearProgress: (() -> Void)? = nil) {
        self.model = model
        self.isInstalled = isInstalled
        self.isDownloading = isDownloading
        self.progress = progress
        self.onDownload = onDownload
        self.onCancel = onCancel
        self.onClearProgress = onClearProgress
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Model info
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(model.size)
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text(model.reason)
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Action button
            if isInstalled {
                Text("Installed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.success)
            } else if isDownloading {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.5)
                        
                        if let onCancel = onCancel {
                            Button(action: onCancel) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.error)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if let progress = progress, !progress.isEmpty {
                        HStack(spacing: 2) {
                            Text(progress)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(progress.contains("Error") || progress.contains("Failed") || progress.contains("Cancelled") ? DesignSystem.Colors.error : DesignSystem.Colors.warning)
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                            
                            // Show clear button for completed/failed downloads
                            if (progress.contains("Completed") || progress.contains("Failed") || progress.contains("Error") || progress.contains("Cancelled")),
                               let onClearProgress = onClearProgress {
                                Button(action: onClearProgress) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8))
                                        .foregroundColor(DesignSystem.Colors.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else {
                Button(action: onDownload) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 11))
                        Text("Get")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .fill(DesignSystem.Colors.surface.opacity(0.2))
        )
    }
} 
