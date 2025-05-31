import SwiftUI

struct CodeAssistantView: View {
    @ObservedObject var ollamaService: OllamaService
    @State private var codeInput = ""
    @State private var selectedTask: CodeTask = .explain
    @State private var result = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Task Selector
            taskSelector
            
            // Code Input
            codeInputArea
            
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
                ForEach(CodeTask.allCases, id: \.self) { task in
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
                                    .fill(selectedTask == task ? DesignSystem.Colors.success : DesignSystem.Colors.surface.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
    }
    
    private var codeInputArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Code")
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.surface.opacity(0.3))
                    .frame(height: 100)
                
                if codeInput.isEmpty {
                    Text("Paste your code here...")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(DesignSystem.Spacing.md)
                }
                
                TextEditor(text: $codeInput)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(DesignSystem.Spacing.sm)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var processButton: some View {
        Button(action: processCode) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: selectedTask == .explain ? "brain.head.profile" : 
                          selectedTask == .review ? "checkmark.circle" :
                          selectedTask == .optimize ? "speedometer" :
                          selectedTask == .debug ? "ladybug" :
                          selectedTask == .document ? "doc.text" : "arrow.triangle.2.circlepath")
                }
                
                Text("\(selectedTask.rawValue)")
                    .font(DesignSystem.Typography.bodyMedium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                          DesignSystem.Colors.textSecondary : DesignSystem.Colors.success)
            )
        }
        .buttonStyle(.plain)
        .disabled(codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
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
    
    private func processCode() {
        let code = codeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !isProcessing else { return }
        
        isProcessing = true
        result = ""
        
        Task {
            let response = await ollamaService.processCode(code: code, task: selectedTask)
            result = response
            isProcessing = false
        }
    }
} 