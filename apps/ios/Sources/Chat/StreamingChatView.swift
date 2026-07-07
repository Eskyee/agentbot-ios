import SwiftUI

struct StreamingChatView: View {
    let conversationId: String
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var streamingText = ""
    @State private var isConnected = false
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
            // Connection status bar
            if !isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("Reconnecting...")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(6)
                .frame(maxWidth: .infinity)
                .background(AgentbotBrand.warn)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Streaming indicator
                        if isStreaming && !streamingText.isEmpty {
                            MessageBubble(message: ChatMessage(
                                id: "streaming",
                                role: "assistant",
                                content: streamingText,
                                timestamp: nil,
                                isStreaming: true
                            ))
                            .id("streaming")
                        }
                        
                        if isStreaming && streamingText.isEmpty {
                            HStack {
                                ThinkingIndicator()
                                Spacer()
                            }
                            .id("thinking")
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
                .onChange(of: streamingText) {
                    withAnimation {
                        proxy.scrollTo("streaming", anchor: .bottom)
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
                    if isStreaming {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.isEmpty ? .gray : AgentbotBrand.accent)
                    }
                }
                .disabled(inputText.isEmpty || isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupWebSocket()
        }
        .onDisappear {
            ws.disconnect()
        }
    }
    
    private func setupWebSocket() {
        ws.onMessage = { message in
            Task { @MainActor in
                handleWebSocketMessage(message)
            }
        }
        ws.onDisconnect = {
            Task { @MainActor in
                isConnected = false
                // Auto-reconnect after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    ws.connect()
                }
            }
        }
        
        if ws.isConnected {
            isConnected = true
            sendJoinMessage()
        } else {
            ws.connect()
            // Wait for connection then join
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isConnected = ws.isConnected
                if isConnected { sendJoinMessage() }
            }
        }
    }
    
    private func sendJoinMessage() {
        let join: [String: Any] = [
            "type": "join",
            "conversationId": conversationId,
            "userId": AuthManager.shared.currentUser?.id ?? "unknown"
        ]
        if let data = try? JSONSerialization.data(withJSONObject: join),
           let json = String(data: data, encoding: .utf8) {
            ws.send(json)
        }
    }
    
    private func handleWebSocketMessage(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        switch type {
        case "connected":
            isConnected = true
            sendJoinMessage()
            
        case "message_start":
            isStreaming = true
            streamingText = ""
            
        case "message_delta":
            if let delta = json["delta"] as? String {
                streamingText += delta
            }
            
        case "message_stop":
            if !streamingText.isEmpty {
                let assistantMessage = ChatMessage(
                    id: UUID().uuidString,
                    role: "assistant",
                    content: streamingText,
                    timestamp: Date(),
                    isStreaming: false
                )
                messages.append(assistantMessage)
            }
            streamingText = ""
            isStreaming = false
            
        case "message":
            if let content = json["content"] as? String,
               let role = json["role"] as? String {
                let message = ChatMessage(
                    id: json["id"] as? String ?? UUID().uuidString,
                    role: role,
                    content: content,
                    timestamp: Date(),
                    isStreaming: false
                )
                messages.append(message)
            }
            
        case "error":
            let errorMsg = json["message"] as? String ?? "Unknown error"
            messages.append(ChatMessage(
                id: UUID().uuidString,
                role: "assistant",
                content: "Error: \(errorMsg)",
                timestamp: Date(),
                isStreaming: false
            ))
            isStreaming = false
            
        default:
            break
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: "user",
            content: text,
            timestamp: Date(),
            isStreaming: nil
        )
        messages.append(userMessage)
        inputText = ""
        isStreaming = true
        streamingText = ""
        
        // Send via WebSocket
        let payload: [String: Any] = [
            "type": "message",
            "conversationId": conversationId,
            "content": text,
            "stream": true
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let json = String(data: data, encoding: .utf8) {
            ws.send(json)
        } else {
            // Fallback to HTTP if WebSocket fails
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
                        messages.append(ChatMessage(
                            id: UUID().uuidString,
                            role: "assistant",
                            content: "Error: \(error.localizedDescription)",
                            timestamp: Date(),
                            isStreaming: nil
                        ))
                        isStreaming = false
                    }
                }
            }
        }
    }
}

struct ThinkingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AgentbotBrand.accent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(12)
        .background(AgentbotBrand.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { animating = true }
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
