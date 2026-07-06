import Foundation

@MainActor
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private let endpoint = "https://api.agentbot.sh/analytics"
    private var isEnabled = true
    
    func track(event: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        let payload: [String: Any] = [
            "event": event,
            "properties": properties,
            "timestamp": Date().timeIntervalSince1970,
            "platform": "ios",
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}