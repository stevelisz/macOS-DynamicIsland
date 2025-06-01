import SwiftUI

struct ChatHistoryView: View {
    @ObservedObject var ollamaService: OllamaService
    @Binding var showingHistory: Bool
    @State private var conversations: [ChatConversation] = []
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: ChatConversation?
    @State private var showingClearAllAlert = false
    
    var filteredConversations: [ChatConversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return UserDefaults.standard.searchConversations(query: searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Background with glassmorphism
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xxl, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xxl, style: .continuous)
                        .fill(Color.black.opacity(0.1))
                        .blur(radius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xxl, style: .continuous)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                headerView
                
                // Search Bar
                searchBar
                
                // Conversations List
                conversationsList
                
                // Bottom Actions
                bottomActions
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .frame(width: 400, height: 500)
        .onAppear {
            loadConversations()
            // Notify that sheet is presented to pause auto-hide
            NotificationCenter.default.post(name: .sheetPresented, object: nil)
        }
        .onDisappear {
            // Notify that sheet is dismissed to resume auto-hide
            NotificationCenter.default.post(name: .sheetDismissed, object: nil)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text("Chat History")
                    .font(DesignSystem.Typography.headline2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("\(conversations.count) conversation\(conversations.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: createNewChat) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
            .scaleEffect(1.0)
            .onHover { isHovered in
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Add subtle hover effect if needed
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .font(.system(size: 14, weight: .medium))
            
            TextField("Search conversations...", text: $searchText)
                .textFieldStyle(.plain)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                        .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                )
        )
    }
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredConversations) { conversation in
                        ConversationRowView(
                            conversation: conversation,
                            isSelected: UserDefaults.standard.currentConversationId == conversation.id,
                            onSelect: { selectConversation(conversation) },
                            onDelete: { deleteConversation(conversation) }
                        )
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
        .frame(maxHeight: 280) // Increased height for better usability
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(Color.clear)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "message.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(searchText.isEmpty ? "No conversations yet" : "No matching conversations")
                    .font(DesignSystem.Typography.headline3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(searchText.isEmpty ? "Start a new conversation to begin" : "Try a different search term")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            if searchText.isEmpty {
                Button("Start New Chat") {
                    createNewChat()
                }
                .font(DesignSystem.Typography.bodySemibold)
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(DesignSystem.Colors.primary)
                )
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
    
    private var bottomActions: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Button(action: { showingClearAllAlert = true }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                    Text("Clear All")
                        .font(DesignSystem.Typography.captionMedium)
                }
                .foregroundColor(DesignSystem.Colors.error)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md, style: .continuous)
                        .fill(DesignSystem.Colors.error.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md, style: .continuous)
                                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(conversations.isEmpty)
            .opacity(conversations.isEmpty ? 0.5 : 1.0)
            
            Spacer()
            
            Button("Back to Chat") {
                backToCurrentChat()
            }
            .font(DesignSystem.Typography.bodySemibold)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md, style: .continuous)
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md, style: .continuous)
                            .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .buttonStyle(.plain)
        }
        .alert("Clear All Conversations", isPresented: $showingClearAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllConversations()
            }
        } message: {
            Text("This will permanently delete all chat conversations. This action cannot be undone.")
        }
        .alert("Delete Conversation", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let conversation = conversationToDelete {
                    confirmDeleteConversation(conversation)
                }
            }
        } message: {
            Text("Are you sure you want to delete this conversation? This action cannot be undone.")
        }
    }
    
    // MARK: - Actions
    
    private func loadConversations() {
        conversations = UserDefaults.standard.chatConversations
    }
    
    private func createNewChat() {
        let newConversation = UserDefaults.standard.createNewConversation()
        ollamaService.loadConversation(newConversation)
        loadConversations()
        showingHistory = false
    }
    
    private func selectConversation(_ conversation: ChatConversation) {
        UserDefaults.standard.currentConversationId = conversation.id
        ollamaService.loadConversation(conversation)
        showingHistory = false
    }
    
    private func deleteConversation(_ conversation: ChatConversation) {
        conversationToDelete = conversation
        showingDeleteAlert = true
    }
    
    private func confirmDeleteConversation(_ conversation: ChatConversation) {
        UserDefaults.standard.deleteConversation(id: conversation.id)
        loadConversations()
        
        // If we deleted the current conversation, create a new one
        if UserDefaults.standard.currentConversationId == conversation.id {
            createNewChat()
        }
    }
    
    private func clearAllConversations() {
        UserDefaults.standard.clearAllConversations()
        createNewChat()
        loadConversations()
    }
    
    private func backToCurrentChat() {
        showingHistory = false
    }
}

struct ConversationRowView: View {
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
                .frame(width: 10, height: 10)
                .padding(.top, 6)
                .shadow(color: isSelected ? DesignSystem.Colors.primary.opacity(0.3) : .clear, radius: 4)
            
            // Conversation content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text(conversation.title)
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
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
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : 
                     (isHovered ? DesignSystem.Colors.surface.opacity(0.5) : DesignSystem.Colors.surface.opacity(0.3)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg, style: .continuous)
                .stroke(isSelected ? DesignSystem.Colors.primary.opacity(0.4) : 
                       (isHovered ? DesignSystem.Colors.border.opacity(0.8) : DesignSystem.Colors.border.opacity(0.3)), 
                       lineWidth: isSelected ? 1.5 : 0.5)
        )
        .shadow(
            color: isSelected ? DesignSystem.Colors.primary.opacity(0.1) : .clear,
            radius: isSelected ? 8 : 0,
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