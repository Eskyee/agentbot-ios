import Foundation

struct ChatConversation: Identifiable, Codable {
    let id: String
    var title: String
    var lastMessage: String
    var lastMessageDate: Date
    var messageCount: Int

    init(id: String = UUID().uuidString, title: String = "New Chat", lastMessage: String = "", lastMessageDate: Date = Date(), messageCount: Int = 0) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.messageCount = messageCount
    }
}

struct ChatStoredMessage: Identifiable, Codable {
    let id: String
    let role: String
    let content: String
    let timestamp: Date

    init(id: String = UUID().uuidString, role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

@MainActor
final class ChatHistoryManager: ObservableObject {
    static let shared = ChatHistoryManager()

    @Published var conversations: [ChatConversation] = []

    private let conversationsKey = "agentbot.chat.conversations"
    private let messagesKey = "agentbot.chat.messages"

    private init() {
        loadConversations()
    }

    func createConversation() -> ChatConversation {
        var conv = ChatConversation()
        conv.title = "Chat \(conversations.count + 1)"
        conversations.insert(conv, at: 0)
        saveConversations()
        return conv
    }

    func updateConversation(_ id: String, lastMessage: String, title: String? = nil) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].lastMessage = lastMessage
        conversations[index].lastMessageDate = Date()
        conversations[index].messageCount += 1
        if let title, !title.isEmpty {
            conversations[index].title = title
        } else if conversations[index].title == "New Chat" || conversations[index].title.hasPrefix("Chat ") {
            conversations[index].title = String(lastMessage.prefix(40))
        }
        saveConversations()
    }

    func deleteConversation(_ id: String) {
        conversations.removeAll { $0.id == id }
        saveConversations()
        clearMessages(for: id)
    }

    func loadMessages(for conversationId: String) -> [ChatStoredMessage] {
        guard let data = UserDefaults.standard.data(forKey: "\(messagesKey).\(conversationId)"),
              let messages = try? JSONDecoder().decode([ChatStoredMessage].self, from: data) else {
            return []
        }
        return messages
    }

    func saveMessage(_ message: ChatStoredMessage, to conversationId: String) {
        var messages = loadMessages(for: conversationId)
        messages.append(message)
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: "\(messagesKey).\(conversationId)")
        }
    }

    private func clearMessages(for conversationId: String) {
        UserDefaults.standard.removeObject(forKey: "\(messagesKey).\(conversationId)")
    }

    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: conversationsKey),
              let saved = try? JSONDecoder().decode([ChatConversation].self, from: data) else {
            return
        }
        conversations = saved
    }

    private func saveConversations() {
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: conversationsKey)
        }
    }
}
