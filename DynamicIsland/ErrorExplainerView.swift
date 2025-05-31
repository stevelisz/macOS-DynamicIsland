import SwiftUI

struct ErrorExplainerView: View {
    @ObservedObject var ollamaService: OllamaService
    @State private var errorInput = ""
    @State private var explanation = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Error Input
            errorInputArea
            
            // Analyze Button
            analyzeButton
            
            // Explanation Area
            if !explanation.isEmpty {
                explanationArea
            }
        }
    }
    
    private var errorInputArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Error Message or Stack Trace")
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.surface.opacity(0.3))
                    .frame(height: 120)
                
                if errorInput.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Paste your error message here...")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        Text("• Exception messages\n• Stack traces\n• Compiler errors\n• Runtime errors")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary.opacity(0.7))
                    }
                    .padding(DesignSystem.Spacing.md)
                }
                
                TextEditor(text: $errorInput)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(DesignSystem.Spacing.sm)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var analyzeButton: some View {
        Button(action: analyzeError) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "stethoscope")
                }
                
                Text("Analyze Error")
                    .font(DesignSystem.Typography.bodyMedium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(errorInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                          DesignSystem.Colors.textSecondary : DesignSystem.Colors.error)
            )
        }
        .buttonStyle(.plain)
        .disabled(errorInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
    }
    
    private var explanationArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("AI Diagnosis")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(explanation, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                Text(explanation)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignSystem.Spacing.sm)
            }
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.surface.opacity(0.3))
            )
        }
    }
    
    private func analyzeError() {
        let error = errorInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !error.isEmpty, !isProcessing else { return }
        
        isProcessing = true
        explanation = ""
        
        Task {
            let response = await ollamaService.explainError(error: error)
            explanation = response
            isProcessing = false
        }
    }
} 