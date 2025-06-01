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
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Header
            headerView
            
            // Search Bar
            searchBar
            
            // Conversations List
            conversationsList
            
            // Bottom Actions
            bottomActions
        }
        .onAppear {
            loadConversations()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text("Chat History")
                    .font(DesignSystem.Typography.headline3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("\(conversations.count) conversation\(conversations.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: createNewChat) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .font(.system(size: 12))
            
            TextField("Search conversations...", text: $searchText)
                .textFieldStyle(.plain)
                .font(DesignSystem.Typography.body)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .fill(DesignSystem.Colors.surface.opacity(0.3))
        )
    }
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xs) {
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
        .frame(height: 140)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "message.circle")
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text(searchText.isEmpty ? "No conversations yet" : "No matching conversations")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            if searchText.isEmpty {
                Button("Start New Chat", action: createNewChat)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.lg)
    }
    
    private var bottomActions: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Button(action: { showingClearAllAlert = true }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                    Text("Clear All")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundColor(DesignSystem.Colors.error)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                        .fill(DesignSystem.Colors.error.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .disabled(conversations.isEmpty)
            
            Spacer()
            
            Button("Back to Chat", action: backToCurrentChat)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.primary)
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
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // Selection indicator
            Circle()
                .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            
            // Conversation content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                HStack {
                    Text(conversation.title)
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(conversation.messageCount)")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignSystem.Colors.surface.opacity(0.5))
                        )
                }
                
                Text(conversation.preview)
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Text(conversation.formattedDate)
                        .font(.system(size: 9))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Spacer()
                    
                    if isHovered {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : 
                     (isHovered ? DesignSystem.Colors.surface.opacity(0.3) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .stroke(isSelected ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
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