import SwiftUI

struct ChatHistoryView: View {
    @StateObject private var history = ChatHistoryManager.shared
    @State private var showNewChat = false

    var body: some View {
        NavigationStack {
            Group {
                if history.conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let conv = history.createConversation()
                        showNewChat = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showNewChat) {
                if let conversation = history.conversations.first {
                    StreamingChatView(
                        conversationId: conversation.id,
                        conversationTitle: conversation.title
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(AgentbotBrand.accent.opacity(0.4))

            Text("No conversations yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Start a new chat with your AI assistant")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Button {
                let conv = history.createConversation()
                showNewChat = true
            } label: {
                Label("New Chat", systemImage: "plus.bubble")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AgentbotBrand.accent)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var conversationList: some View {
        List {
            ForEach(history.conversations) { conversation in
                NavigationLink {
                    StreamingChatView(
                        conversationId: conversation.id,
                        conversationTitle: conversation.title
                    )
                } label: {
                    ConversationRow(conversation: conversation)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        history.deleteConversation(conversation.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct ConversationRow: View {
    let conversation: ChatConversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)

            if !conversation.lastMessage.isEmpty {
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(conversation.lastMessageDate, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if conversation.messageCount > 0 {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(conversation.messageCount) messages")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
