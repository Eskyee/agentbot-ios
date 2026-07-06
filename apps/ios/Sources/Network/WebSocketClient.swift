import Foundation

@MainActor
final class WebSocketClient: ObservableObject {
    static let shared = WebSocketClient()
    
    @Published var isConnected = false
    @Published var lastMessage: String?
    
    private var webSocket: URLSessionWebSocketTask?
    private var heartbeatTask: Task<Void, Never>?
    
    var onMessage: ((String) -> Void)?
    var onDisconnect: (() -> Void)?
    
    func connect() {
        guard let token = AuthManager.shared.token else { return }
        
        let url = URL(string: "wss://api.agentbot.sh/ws?token=\(token)")!
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        isConnected = true
        
        startReceiving()
        startHeartbeat()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
        heartbeatTask?.cancel()
    }
    
    func send(_ message: String) {
        webSocket?.send(.string(message)) { error in
            if let error = error {
                print("[Agentbot] WebSocket send error: \(error)")
            }
        }
    }
    
    func send<T: Encodable>(_ object: T) {
        guard let data = try? JSONEncoder().encode(object),
              let json = String(data: data, encoding: .utf8) else { return }
        send(json)
    }
    
    private func startReceiving() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self?.lastMessage = text
                        self?.onMessage?(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self?.lastMessage = text
                            self?.onMessage?(text)
                        }
                    @unknown default: break
                    }
                    self?.startReceiving()
                case .failure:
                    self?.isConnected = false
                    self?.onDisconnect?()
                }
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                send("{\"type\":\"ping\"}")
            }
        }
    }
}