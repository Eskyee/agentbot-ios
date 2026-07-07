import Foundation

@MainActor
final class WebSocketClient: ObservableObject {
    static let shared = WebSocketClient()
    
    @Published var isConnected = false
    @Published var lastMessage: String?
    
    private var webSocket: URLSessionWebSocketTask?
    private var heartbeatTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    
    var onMessage: ((String) -> Void)?
    var onDisconnect: (() -> Void)?
    var onConnect: (() -> Void)?
    
    private var baseURL: URL {
        URL(string: "wss://agentbot-backend.fly.dev/ws/chat")!
    }
    
    func connect() {
        guard !isConnected else { return }
        
        guard let token = AuthManager.shared.token else {
            print("[Agentbot] No auth token, cannot connect WebSocket")
            return
        }
        
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "token", value: token)]
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: urlComponents.url!)
        webSocket?.resume()
        
        isConnected = true
        onConnect?()
        
        startReceiving()
        startHeartbeat()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
        heartbeatTask?.cancel()
        reconnectTask?.cancel()
    }
    
    func send(_ message: String) {
        guard isConnected else {
            print("[Agentbot] WebSocket not connected, cannot send")
            return
        }
        
        webSocket?.send(.string(message)) { error in
            if let error = error {
                print("[Agentbot] WebSocket send error: \(error)")
                Task { @MainActor in
                    self.isConnected = false
                    self.onDisconnect?()
                }
            }
        }
    }
    
    func send<T: Encodable>(_ object: T) {
        guard let data = try? JSONEncoder().encode(object),
              let json = String(data: data, encoding: .utf8) else { return }
        send(json)
    }
    
    func send(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else { return }
        send(json)
    }
    
    private func startReceiving() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.lastMessage = text
                        self.onMessage?(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.lastMessage = text
                            self.onMessage?(text)
                        }
                    @unknown default:
                        break
                    }
                    self.startReceiving()
                    
                case .failure(let error):
                    print("[Agentbot] WebSocket receive error: \(error)")
                    self.isConnected = false
                    self.onDisconnect?()
                    self.scheduleReconnect()
                }
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled, isConnected else { break }
                send(["type": "ping", "timestamp": Date().timeIntervalSince1970])
            }
        }
    }
    
    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, !isConnected else { return }
            print("[Agentbot] Attempting WebSocket reconnect...")
            connect()
        }
    }
}
