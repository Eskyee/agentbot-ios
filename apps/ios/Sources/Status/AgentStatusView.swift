import SwiftUI

struct AgentStatusView: View {
    @State private var agents: [AgentStatus] = []
    @State private var isLoading = true

    struct AgentStatus: Identifiable, Codable {
        let id: String
        let name: String
        let status: Status
        let lastSeen: Date?
        let model: String?

        enum Status: String, Codable {
            case online, offline, busy, error

            var color: Color {
                switch self {
                case .online: return .green
                case .offline: return .gray
                case .busy: return .orange
                case .error: return .red
                }
            }

            var icon: String {
                switch self {
                case .online: return "circle.fill"
                case .offline: return "circle"
                case .busy: return "circle.fill"
                case .error: return "exclamationmark.circle.fill"
                }
            }
        }
    }

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading agents...")
            } else if agents.isEmpty {
                ContentUnavailableView(
                    "No Agents",
                    systemImage: "brain.head.profile",
                    description: Text("Connect to a gateway to see your agents.")
                )
            } else {
                ForEach(agents) { agent in
                    HStack {
                        Image(systemName: agent.status.icon)
                            .foregroundStyle(agent.status.color)
                        VStack(alignment: .leading) {
                            Text(agent.name).font(.headline)
                            Text(agent.status.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let model = agent.model {
                            Text(model)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Agents")
        .refreshable {
            await loadAgents()
        }
        .task {
            await loadAgents()
        }
    }

    private func loadAgents() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/agents")
            agents = try JSONDecoder().decode([AgentStatus].self, from: data)
        } catch {
            agents = []
        }
        isLoading = false
    }
}
