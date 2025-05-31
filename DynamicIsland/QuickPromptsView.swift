import SwiftUI

struct QuickPromptsView: View {
    @ObservedObject var ollamaService: OllamaService
    @State private var selectedPrompt: QuickPrompt?
    @State private var result = ""
    @State private var isProcessing = false
    @State private var customInput = ""
    
    private let prompts = QuickPrompt.allPrompts
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Prompt Grid
            promptGrid
            
            // Custom Input (if selected prompt needs it)
            if let selectedPrompt = selectedPrompt, selectedPrompt.needsInput {
                customInputArea
            }
            
            // Execute Button
            if selectedPrompt != nil {
                executeButton
            }
            
            // Result Area
            if !result.isEmpty {
                resultArea
            }
        }
    }
    
    private var promptGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.xs), count: 2)
        
        return LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.xs) {
            ForEach(prompts) { prompt in
                PromptCard(
                    prompt: prompt,
                    isSelected: selectedPrompt?.id == prompt.id
                ) {
                    selectedPrompt = prompt
                    result = ""
                    customInput = ""
                }
            }
        }
    }
    
    private var customInputArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(selectedPrompt?.inputPlaceholder ?? "Input")
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField("Enter details...", text: $customInput, axis: .vertical)
                .textFieldStyle(.plain)
                .font(DesignSystem.Typography.body)
                .padding(DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(DesignSystem.Colors.surface.opacity(0.3))
                )
        }
    }
    
    private var executeButton: some View {
        Button(action: executePrompt) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: selectedPrompt?.icon ?? "bolt.fill")
                }
                
                Text("Execute")
                    .font(DesignSystem.Typography.bodyMedium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(canExecute ? DesignSystem.Colors.warning : DesignSystem.Colors.textSecondary)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canExecute || isProcessing)
    }
    
    private var canExecute: Bool {
        guard let selectedPrompt = selectedPrompt else { return false }
        if selectedPrompt.needsInput {
            return !customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
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
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(DesignSystem.Colors.surface.opacity(0.3))
            )
        }
    }
    
    private func executePrompt() {
        guard let selectedPrompt = selectedPrompt, canExecute, !isProcessing else { return }
        
        isProcessing = true
        result = ""
        
        let prompt = selectedPrompt.buildPrompt(input: customInput)
        
        Task {
            let response = await ollamaService.sendMessage(prompt)
            result = response
            isProcessing = false
        }
    }
}

struct PromptCard: View {
    let prompt: QuickPrompt
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: prompt.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : prompt.color)
                
                Text(prompt.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .fill(isSelected ? prompt.color : DesignSystem.Colors.surface.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                    .stroke(isSelected ? prompt.color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Prompt Definitions

struct QuickPrompt: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let prompt: String
    let needsInput: Bool
    let inputPlaceholder: String?
    
    func buildPrompt(input: String = "") -> String {
        if needsInput && !input.isEmpty {
            return prompt.replacingOccurrences(of: "{INPUT}", with: input)
        }
        return prompt
    }
    
    static let allPrompts: [QuickPrompt] = [
        QuickPrompt(
            title: "Meeting Summary",
            icon: "person.2.circle",
            color: DesignSystem.Colors.primary,
            prompt: "Please create a concise meeting summary with key points, action items, and decisions from: {INPUT}",
            needsInput: true,
            inputPlaceholder: "Meeting notes or transcript"
        ),
        
        QuickPrompt(
            title: "Email Reply",
            icon: "envelope.circle",
            color: DesignSystem.Colors.clipboard,
            prompt: "Please write a professional email reply to: {INPUT}",
            needsInput: true,
            inputPlaceholder: "Original email content"
        ),
        
        QuickPrompt(
            title: "Code Comments",
            icon: "chevron.left.forwardslash.chevron.right",
            color: DesignSystem.Colors.success,
            prompt: "Please add detailed comments to this code explaining what it does: {INPUT}",
            needsInput: true,
            inputPlaceholder: "Code to comment"
        ),
        
        QuickPrompt(
            title: "Git Commit",
            icon: "arrow.branch",
            color: DesignSystem.Colors.warning,
            prompt: "Please write a clear, conventional commit message for these changes: {INPUT}",
            needsInput: true,
            inputPlaceholder: "Description of changes"
        ),
        
        QuickPrompt(
            title: "Dad Joke",
            icon: "face.smiling",
            color: DesignSystem.Colors.files,
            prompt: "Tell me a clean, family-friendly dad joke",
            needsInput: false,
            inputPlaceholder: nil
        ),
        
        QuickPrompt(
            title: "Productivity Tip",
            icon: "lightbulb.circle",
            color: DesignSystem.Colors.system,
            prompt: "Give me a practical productivity tip for {INPUT}",
            needsInput: true,
            inputPlaceholder: "Area (e.g., coding, writing, studying)"
        ),
        
        QuickPrompt(
            title: "Quick Recipe",
            icon: "fork.knife.circle",
            color: DesignSystem.Colors.error,
            prompt: "Give me a quick and easy recipe for {INPUT} with ingredients and steps",
            needsInput: true,
            inputPlaceholder: "Dish or ingredient"
        ),
        
        QuickPrompt(
            title: "Learning Path",
            icon: "graduationcap.circle",
            color: DesignSystem.Colors.primary,
            prompt: "Create a learning roadmap for {INPUT} with key topics and resources",
            needsInput: true,
            inputPlaceholder: "Technology or skill"
        )
    ]
} 