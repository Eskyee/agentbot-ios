import SwiftUI

struct ScheduledAutomationsView: View {
    @State private var automations: [Automation] = []
    @State private var isLoading = true
    
    struct Automation: Identifiable, Codable {
        let id: String
        let name: String
        let description: String?
        let schedule: String
        let isEnabled: Bool
        let lastRun: Date?
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading automations...")
            } else if automations.isEmpty {
                ContentUnavailableView(
                    "No Automations",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Create automations to make your agents proactive.")
                )
            } else {
                ForEach(automations) { auto in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(auto.name).font(.headline)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { auto.isEnabled },
                                set: { _ in toggleAutomation(auto) }
                            ))
                            .labelsHidden()
                        }
                        if let desc = auto.description {
                            Text(desc).font(.subheadline).foregroundStyle(.secondary)
                        }
                        HStack {
                            Label(auto.schedule, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let lastRun = auto.lastRun {
                                Text("Last: \(lastRun, style: .relative) ago")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Automations")
        .task { await loadAutomations() }
    }
    
    private func loadAutomations() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/automations")
            automations = try JSONDecoder().decode([Automation].self, from: data)
        } catch { automations = [] }
        isLoading = false
    }
    
    private func toggleAutomation(_ automation: Automation) {
        Task {
            _ = try? await AuthManager.shared.authorizedRequest(
                path: "/api/automations/\(automation.id)/toggle",
                method: "POST"
            )
            await loadAutomations()
        }
    }
}