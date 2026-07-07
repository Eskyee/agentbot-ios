import Foundation

@MainActor
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private let endpoint = "https://agentbot-backend.fly.dev/api/analytics"
    private var isEnabled = true
    private var sessionID = UUID().uuidString
    private var startTime = Date()
    
    func track(event: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        let payload: [String: Any] = [
            "event": event,
            "properties": properties,
            "timestamp": Date().timeIntervalSince1970,
            "platform": "ios",
            "sessionId": sessionID,
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "unknown",
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    func trackScreenView(_ screen: String) {
        track(event: "screen_view", properties: ["screen": screen])
    }
    
    func trackButtonTap(_ button: String, screen: String) {
        track(event: "button_tap", properties: ["button": button, "screen": screen])
    }
    
    func trackFeatureUsed(_ feature: String) {
        track(event: "feature_used", properties: ["feature": feature])
    }
    
    func trackError(_ error: String, context: String? = nil) {
        var props: [String: Any] = ["error": error]
        if let context = context { props["context"] = context }
        track(event: "error", properties: props)
    }
    
    func trackSessionStart() {
        startTime = Date()
        track(event: "session_start")
    }
    
    func trackSessionEnd() {
        let duration = Date().timeIntervalSince(startTime)
        track(event: "session_end", properties: ["duration": duration])
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
    }
    
    func loadSettings() {
        isEnabled = UserDefaults.standard.object(forKey: "analytics_enabled") as? Bool ?? true
    }
}
