import Foundation

enum FeatureFlags {
    static let pushNotificationsEnabled = true
    static let voiceInputEnabled = true
    static let agentMonitoringEnabled = true
    static let liveLogsEnabled = true
    static let deviceManagementEnabled = true
    static let sessionControlsEnabled = true
    static let skillsCatalogEnabled = true
    static let marketplaceEnabled = true
    
    static let apiBaseURL = URL(string: "https://agentbot-backend.fly.dev")!
    static let wsBaseURL = URL(string: "wss://agentbot-backend.fly.dev")!
}
