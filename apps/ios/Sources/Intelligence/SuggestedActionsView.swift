import SwiftUI

struct SuggestedActionsView: View {
    @State private var suggestions: [Suggestion] = []
    @State private var isLoading = true
    
    struct Suggestion: Identifiable, Codable {
        let id: String
        let title: String
        let description: String
        let type: SuggestionType
        let action: String?
        let confidence: Double?
        
        enum SuggestionType: String, Codable {
            case quickAction, followUp, reminder, automation
            
            var icon: String {
                switch self {
                case .quickAction: return "bolt.fill"
                case .followUp: return "arrow.right.circle"
                case .reminder: return "bell.fill"
                case .automation: return "gearshape.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .quickAction: return .blue
                case .followUp: return .green
                case .reminder: return .orange
                case .automation: return .purple
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading suggestions...")
                    .frame(maxHeight: .infinity)
            } else if suggestions.isEmpty {
                ContentUnavailableView(
                    "No Suggestions",
                    systemImage: "lightbulb",
                    description: Text("Your agent will suggest actions based on your activity.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(suggestions) { suggestion in
                            SuggestionCard(suggestion: suggestion) {
                                Task { await executeSuggestion(suggestion) }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Suggestions")
        .refreshable { await loadSuggestions() }
        .task { await loadSuggestions() }
    }
    
    private func loadSuggestions() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/suggestions")
            suggestions = try JSONDecoder().decode([Suggestion].self, from: data)
        } catch { suggestions = [] }
        isLoading = false
    }
    
    private func executeSuggestion(_ suggestion: Suggestion) async {
        guard let action = suggestion.action else { return }
        _ = try? await AuthManager.shared.authorizedRequest(
            path: "/api/suggestions/\(suggestion.id)/execute",
            method: "POST",
            body: ["action": action]
        )
        suggestions.removeAll { $0.id == suggestion.id }
    }
}

private struct SuggestionCard: View {
    let suggestion: SuggestedActionsView.Suggestion
    let onExecute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: suggestion.type.icon)
                    .font(.title3)
                    .foregroundStyle(suggestion.type.color)
                VStack(alignment: .leading) {
                    Text(suggestion.title)
                        .font(.headline)
                    Text(suggestion.type.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let confidence = suggestion.confidence {
                    Text("\(Int(confidence * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
            
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if suggestion.action != nil {
                Button {
                    onExecute()
                } label: {
                    Text("Execute")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AgentbotBrand.accent.opacity(0.1))
                        .foregroundStyle(AgentbotBrand.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
