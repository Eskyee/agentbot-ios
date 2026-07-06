import SwiftUI

struct StreamingChatView: View {
    let conversationId: String
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var selectedImage: UIImage?
    @StateObject private var ws = WebSocketClient.shared
    
    struct ChatMessage: Identifiable, Codable {
        let id: String
        let role: String
        let content: String
        let timestamp: Date?
        let isStreaming: Bool?
        
        var isUser: Bool { role == "user" }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button { /* image picker */ } label: {
                    Image(systemName: "photo")
                        .foregroundStyle(AgentbotBrand.accent)
                }
                
                TextField("Message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.isEmpty ? .gray : AgentbotBrand.accent)
                }
                .disabled(inputText.isEmpty || isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(id: UUID().uuidString, role: "user", content: text, timestamp: Date(), isStreaming: nil)
        messages.append(userMessage)
        inputText = ""
        isStreaming = true
        
        Task {
            do {
                let data = try await AuthManager.shared.authorizedRequest(
                    path: "/api/conversations/\(conversationId)/messages",
                    method: "POST",
                    body: ["content": text]
                )
                let response = try JSONDecoder().decode(ChatMessage.self, from: data)
                await MainActor.run {
                    messages.append(response)
                    isStreaming = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(id: UUID().uuidString, role: "assistant", content: "Error: \(error.localizedDescription)", timestamp: Date(), isStreaming: nil))
                    isStreaming = false
                }
            }
        }
    }
}

private struct MessageBubble: View {
    let message: StreamingChatView.ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? AgentbotBrand.accent : Color(.systemGray5))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if let ts = message.timestamp {
                    Text(ts, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if !message.isUser { Spacer() }
        }
    }
}