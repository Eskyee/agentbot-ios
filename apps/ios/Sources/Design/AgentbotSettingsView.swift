import SwiftUI

struct AgentbotSettingsView: View {
    @StateObject private var auth = AuthManager.shared
    
    var body: some View {
        List {
            Section("Account") {
                if let user = auth.currentUser {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(user.name ?? "User").font(.headline)
                            Text(user.email ?? "No email").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Button("Sign Out", role: .destructive) {
                    auth.logout()
                }
            }
            
            Section("App") {
                LabeledContent("Version", value: "2026.7.1")
                LabeledContent("Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
            }
            
            Section("Server") {
                LabeledContent("API", value: "api.agentbot.sh")
                LabeledContent("Status", value: "Connected")
                    .foregroundStyle(.green)
            }
            
            Section("Features") {
                NavigationLink("Devices", destination: DeviceManagementView())
                NavigationLink("Sessions", destination: SessionControlsView())
                NavigationLink("Live Logs", destination: LiveLogsView())
                NavigationLink("Voice Input", destination: VoiceInputSettingsView())
            }
            
            Section("About") {
                LabeledContent("Platform", value: "Agentbot")
                LabeledContent("Runtime", value: "OpenClaw")
            }
        }
        .navigationTitle("Settings")
    }
}

private struct VoiceInputSettingsView: View {
    @StateObject private var voiceManager = VoiceInputManager.shared
    
    var body: some View {
        List {
            Section("Speech Recognition") {
                LabeledContent("Status", value: voiceManager.authorizationStatus == .authorized ? "Authorized" : "Not Authorized")
                Button("Request Permission") {
                    Task { await voiceManager.requestAuthorization() }
                }
            }
        }
        .navigationTitle("Voice Input")
    }
}
