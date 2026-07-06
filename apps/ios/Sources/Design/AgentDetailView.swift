import SwiftUI

struct AgentDetailView: View {
    let agent: AgentDashboardView.Agent
    @State private var recentActivity: [ActivityItem] = []
    
    struct ActivityItem: Identifiable, Codable {
        let id: String
        let type: String
        let message: String
        let timestamp: Date
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AgentbotBrand.accent)
                    Text(agent.name).font(.title.bold())
                    HStack {
                        Circle()
                            .fill(agent.status.color)
                            .frame(width: 10, height: 10)
                        Text(agent.status.rawValue.capitalized)
                    }
                    if let desc = agent.description {
                        Text(desc)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                
                if let model = agent.model {
                    LabeledContent("Model", value: model)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Activity")
                        .font(.headline)
                    ForEach(recentActivity) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(AgentbotBrand.accent.opacity(0.2))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            VStack(alignment: .leading) {
                                Text(item.message)
                                    .font(.subheadline)
                                Text(item.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(agent.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadActivity() }
    }
    
    private func loadActivity() async {
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/agents/\(agent.id)/activity")
            recentActivity = try JSONDecoder().decode([ActivityItem].self, from: data)
        } catch { recentActivity = [] }
    }
}