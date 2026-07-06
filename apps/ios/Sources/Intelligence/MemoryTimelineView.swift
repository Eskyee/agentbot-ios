import SwiftUI

struct MemoryTimelineView: View {
    @State private var memories: [MemoryEntry] = []
    @State private var isLoading = true
    
    struct MemoryEntry: Identifiable, Codable {
        let id: String
        let content: String
        let category: String
        let createdAt: Date
        let source: String?
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading memories...")
            } else {
                ForEach(memories) { memory in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(memory.content)
                            .font(.body)
                        HStack {
                            Text(memory.category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AgentbotBrand.accent.opacity(0.1))
                                .foregroundStyle(AgentbotBrand.accent)
                                .clipShape(Capsule())
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
        }
        .navigationTitle("Memory")
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
}