import SwiftUI

struct MemoryTimelineView: View {
    @State private var memories: [MemoryEntry] = []
    @State private var isLoading = true
    @State private var selectedFilter: MemoryFilter = .all
    
    enum MemoryFilter: String, CaseIterable, Identifiable {
        case all, conversation, action, fact, preference
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .conversation: return "bubble.left.and.bubble.right"
            case .action: return "bolt.fill"
            case .fact: return "info.circle"
            case .preference: return "heart.fill"
            }
        }
    }
    
    struct MemoryEntry: Identifiable, Codable {
        let id: String
        let content: String
        let category: String
        let createdAt: Date
        let source: String?
        let importance: Int?
        
        var filter: MemoryFilter {
            switch category {
            case "conversation": return .conversation
            case "action": return .action
            case "fact": return .fact
            case "preference": return .preference
            default: return .all
            }
        }
    }
    
    var filteredMemories: [MemoryEntry] {
        if selectedFilter == .all { return memories }
        return memories.filter { $0.filter == selectedFilter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MemoryFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: filter.icon)
                                    .font(.caption)
                                Text(filter.rawValue.capitalized)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? AgentbotBrand.accent : Color(.systemGray6))
                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            if isLoading {
                ProgressView("Loading memories...")
                    .frame(maxHeight: .infinity)
            } else if filteredMemories.isEmpty {
                ContentUnavailableView(
                    "No Memories",
                    systemImage: "brain",
                    description: Text("Your agent will remember conversations and preferences here.")
                )
            } else {
                List {
                    ForEach(filteredMemories) { memory in
                        MemoryRow(memory: memory)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Memory")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    Task { await clearMemories() }
                }
                .foregroundStyle(.red)
            }
        }
        .refreshable { await loadMemories() }
        .task { await loadMemories() }
    }
    
    private func loadMemories() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/memories")
            memories = try JSONDecoder().decode([MemoryEntry].self, from: data)
        } catch { memories = [] }
        isLoading = false
    }
    
    private func clearMemories() async {
        _ = try? await AuthManager.shared.authorizedRequest(path: "/api/memories", method: "DELETE")
        memories = []
    }
}

private struct MemoryRow: View {
    let memory: MemoryTimelineView.MemoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: memory.filter.icon)
                    .font(.caption)
                    .foregroundStyle(AgentbotBrand.accent)
                Text(memory.category.capitalized)
                    .font(.caption.bold())
                    .foregroundStyle(AgentbotBrand.accent)
                Spacer()
                if let importance = memory.importance {
                    HStack(spacing: 2) {
                        ForEach(0..<importance, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
            Text(memory.content)
                .font(.subheadline)
                .lineLimit(3)
            HStack {
                if let source = memory.source {
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text(memory.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
