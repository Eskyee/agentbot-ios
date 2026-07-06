import SwiftUI

struct AgentDashboardView: View {
    @State private var agents: [Agent] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    struct Agent: Identifiable, Codable {
        let id: String
        let name: String
        let description: String?
        let status: Status
        let model: String?
        let lastActivity: Date?
        let taskCount: Int?
        
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
        }
    }
    
    var filteredAgents: [Agent] {
        if searchText.isEmpty { return agents }
        return agents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading agents...")
                    .frame(maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAgents) { agent in
                        NavigationLink(destination: AgentDetailView(agent: agent)) {
                            AgentCard(agent: agent)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dashboard")
        .searchable(text: $searchText, prompt: "Search agents")
        .refreshable { await loadAgents() }
        .task { await loadAgents() }
    }
    
    private func loadAgents() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/agents")
            agents = try JSONDecoder().decode([Agent].self, from: data)
        } catch { agents = [] }
        isLoading = false
    }
}

private struct AgentCard: View {
    let agent: AgentDashboardView.Agent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .font(.title2)
                    .foregroundStyle(AgentbotBrand.accent)
                VStack(alignment: .leading) {
                    Text(agent.name).font(.headline)
                    HStack {
                        Circle()
                            .fill(agent.status.color)
                            .frame(width: 8, height: 8)
                        Text(agent.status.rawValue.capitalized)
                            .font(.caption)
                    }
                }
                Spacer()
                if let tasks = agent.taskCount {
                    Text("\(tasks) tasks")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if let desc = agent.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                if let model = agent.model {
                    Text(model)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                Spacer()
                if let lastActivity = agent.lastActivity {
                    Text(lastActivity, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}