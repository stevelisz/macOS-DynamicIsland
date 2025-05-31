import SwiftUI

struct TextProcessorView: View {
    @ObservedObject var ollamaService: OllamaService
    @State private var textInput = ""
    @State private var selectedTask: TextTask = .summarize
    @State private var result = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Task Selector
            taskSelector
            
            // Text Input
            textInputArea
            
            // Process Button
            processButton
            
            // Result Area
            if !result.isEmpty {
                resultArea
            }
        }
    }
    
    private var taskSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(TextTask.allCases, id: \.self) { task in
                    Button(action: {
                        selectedTask = task
                    }) {
                        Text(task.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTask == task ? .white : DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                    .fill(selectedTask == task ? DesignSystem.Colors.clipboard : DesignSystem.Colors.surface.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
    }
    
    private var textInputArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Text")
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.surface.opacity(0.3))
                    .frame(height: 100)
                
                if textInput.isEmpty {
                    Text("Enter text to process...")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(DesignSystem.Spacing.md)
                }
                
                TextEditor(text: $textInput)
                    .font(DesignSystem.Typography.body)
                    .padding(DesignSystem.Spacing.sm)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var processButton: some View {
        Button(action: processText) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: taskIcon)
                }
                
                Text("\(selectedTask.rawValue)")
                    .font(DesignSystem.Typography.bodyMedium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                          DesignSystem.Colors.textSecondary : DesignSystem.Colors.clipboard)
            )
        }
        .buttonStyle(.plain)
        .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
    }
    
    private var taskIcon: String {
        switch selectedTask {
        case .summarize: return "doc.text.below.ecg"
        case .translate: return "globe"
        case .rewrite: return "pencil.circle"
        case .expand: return "plus.magnifyingglass"
        case .simplify: return "minus.magnifyingglass"
        case .tone: return "theatermasks"
        }
    }
    
    private var resultArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Result")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(result, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                Text(result)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignSystem.Spacing.sm)
            }
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.surface.opacity(0.3))
            )
        }
    }
    
    private func processText() {
        let text = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isProcessing else { return }
        
        isProcessing = true
        result = ""
        
        Task {
            let response = await ollamaService.processText(text: text, task: selectedTask)
            result = response
            isProcessing = false
        }
    }
} 