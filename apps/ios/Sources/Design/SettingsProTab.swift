import SwiftUI

struct SettingsProTab: View {
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
                            Text(user.email).font(.caption).foregroundStyle(.secondary)
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
            }
        }
        .navigationTitle("Settings")
    }
}
