import SwiftUI

struct SessionControlsView: View {
    @State private var sessions: [Session] = []
    @State private var isLoading = true
    
    struct Session: Identifiable, Codable {
        let id: String
        let name: String
        let status: String
        let startedAt: Date?
        let agentId: String?
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading sessions...")
            } else if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "play.circle",
                    description: Text("Start a session to begin.")
                )
            } else {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(session.name).font(.headline)
                            Spacer()
                            Text(session.status)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(session.status == "active" ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        if let agentId = session.agentId {
                            Text("Agent: \(agentId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            Button("Connect") { connectSession(session) }
                                .buttonStyle(.bordered)
                            Button("Disconnect") { disconnectSession(session) }
                                .buttonStyle(.bordered)
                                .tint(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Sessions")
        .refreshable { await loadSessions() }
        .task { await loadSessions() }
    }
    
    private func loadSessions() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/sessions")
            sessions = try JSONDecoder().decode([Session].self, from: data)
        } catch { sessions = [] }
        isLoading = false
    }
    
    private func connectSession(_ session: Session) {
        Task {
            _ = try? await AuthManager.shared.authorizedRequest(path: "/api/sessions/\(session.id)/connect", method: "POST")
            await loadSessions()
        }
    }
    
    private func disconnectSession(_ session: Session) {
        Task {
            _ = try? await AuthManager.shared.authorizedRequest(path: "/api/sessions/\(session.id)/disconnect", method: "POST")
            await loadSessions()
        }
    }
}
