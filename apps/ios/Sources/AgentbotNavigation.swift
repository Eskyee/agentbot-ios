import SwiftUI

struct AgentbotRootView: View {
    @StateObject private var auth = AuthManager.shared
    
    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await auth.restoreSession()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(0)
            
            NavigationStack {
                AgentStatusView()
            }
            .tabItem {
                Label("Agents", systemImage: "brain.head.profile")
            }
            .tag(1)
            
            NavigationStack {
                SkillsCatalogView()
            }
            .tabItem {
                Label("Skills", systemImage: "puzzlepiece.fill")
            }
            .tag(2)
            
            NavigationStack {
                MarketplaceView()
            }
            .tabItem {
                Label("Market", systemImage: "storefront.fill")
            }
            .tag(3)
            
            NavigationStack {
                AgentbotSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(AgentbotBrand.accent)
    }
}

struct ChatListView: View {
    @State private var conversations: [ChatConversation] = []
    @State private var isLoading = true
    
    struct ChatConversation: Identifiable, Codable {
        let id: String
        let title: String
        let lastMessage: String?
        let updatedAt: Date?
        let agentName: String?
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading conversations...")
            } else if conversations.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Start a new conversation with your agent.")
                )
            } else {
                ForEach(conversations) { convo in
                    NavigationLink(destination: Text("Chat: \(convo.title)")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(convo.title).font(.headline)
                            if let last = convo.lastMessage {
                                Text(last)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            if let agent = convo.agentName {
                                Text(agent)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Agentbot")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: Text("New Chat")) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .refreshable { await loadConversations() }
        .task { await loadConversations() }
    }
    
    private func loadConversations() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/conversations")
            conversations = try JSONDecoder().decode([ChatConversation].self, from: data)
        } catch { conversations = [] }
        isLoading = false
    }
}
