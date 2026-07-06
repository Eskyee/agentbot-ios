import SwiftUI

struct MarketplaceView: View {
    @State private var agents: [MarketplaceAgent] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    struct MarketplaceAgent: Identifiable, Codable {
        let id: String
        let name: String
        let description: String
        let author: String
        let category: String
        let rating: Double
        let installs: Int
        let price: String?
        let isInstalled: Bool
        let iconUrl: String?
    }
    
    var filteredAgents: [MarketplaceAgent] {
        if searchText.isEmpty { return agents }
        return agents.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading marketplace...")
                    .frame(maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredAgents) { agent in
                        AgentMarketplaceCard(agent: agent) {
                            toggleInstall(agent)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Marketplace")
        .searchable(text: $searchText, prompt: "Search agents")
        .refreshable { await loadAgents() }
        .task { await loadAgents() }
    }
    
    private func loadAgents() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/marketplace")
            agents = try JSONDecoder().decode([MarketplaceAgent].self, from: data)
        } catch { agents = [] }
        isLoading = false
    }
    
    private func toggleInstall(_ agent: MarketplaceAgent) {
        Task {
            let path = agent.isInstalled ? "/api/marketplace/\(agent.id)/uninstall" : "/api/marketplace/\(agent.id)/install"
            _ = try? await AuthManager.shared.authorizedRequest(path: path, method: "POST")
            await loadAgents()
        }
    }
}

private struct AgentMarketplaceCard: View {
    let agent: MarketplaceView.MarketplaceAgent
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .font(.title2)
                    .foregroundStyle(AgentbotBrand.accent)
                VStack(alignment: .leading) {
                    Text(agent.name).font(.headline)
                    Text(agent.author).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(agent.isInstalled ? "Installed" : "Get") { onToggle() }
                    .buttonStyle(.bordered)
                    .tint(agent.isInstalled ? .gray : .accentColor)
                    .disabled(agent.isInstalled)
            }
            Text(agent.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(agent.rating, specifier: "%.1f")", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
                Text("\(agent.installs.formatted()) installs")
                Spacer()
                Text(agent.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                if let price = agent.price {
                    Text(price).fontWeight(.semibold)
                } else {
                    Text("Free").foregroundStyle(.green)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
