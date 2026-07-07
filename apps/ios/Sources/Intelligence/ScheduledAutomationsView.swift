import SwiftUI

struct ScheduledAutomationsView: View {
    @State private var automations: [Automation] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    
    struct Automation: Identifiable, Codable {
        let id: String
        let name: String
        let description: String?
        let schedule: String
        let isEnabled: Bool
        let lastRun: Date?
        let nextRun: Date?
        let actionCount: Int?
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
                ForEach(automations) { automation in
                    AutomationRow(automation: automation) {
                        Task { await toggleAutomation(automation) }
                    }
                }
            }
        }
        .navigationTitle("Automations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateAutomationSheet()
        }
        .refreshable { await loadAutomations() }
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
    
    private func toggleAutomation(_ automation: Automation) async {
        _ = try? await AuthManager.shared.authorizedRequest(
            path: "/api/automations/\(automation.id)/toggle",
            method: "POST"
        )
        await loadAutomations()
    }
}

private struct AutomationRow: View {
    let automation: ScheduledAutomationsView.Automation
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(automation.name)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { automation.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(AgentbotBrand.accent)
            }
            
            if let desc = automation.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                Label(automation.schedule, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let tasks = automation.actionCount {
                    Label("\(tasks) tasks", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let lastRun = automation.lastRun {
                    Text("Last: \(lastRun, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateAutomationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var schedule = "Daily"
    @State private var isCreating = false
    
    let schedules = ["Hourly", "Daily", "Weekly", "Monthly"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Automation Details") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description)
                }
                
                Section("Schedule") {
                    Picker("Frequency", selection: $schedule) {
                        ForEach(schedules, id: \.self) { schedule in
                            Text(schedule).tag(schedule)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button {
                        Task { await createAutomation() }
                    } label: {
                        if isCreating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Automation")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || isCreating)
                }
            }
            .navigationTitle("New Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createAutomation() async {
        isCreating = true
        
        struct CreateRequest: Codable {
            let name: String
            let description: String
            let schedule: String
        }
        
        let body = CreateRequest(name: name, description: description, schedule: schedule)
        _ = try? await AuthManager.shared.authorizedRequest(
            path: "/api/automations",
            method: "POST",
            body: body
        )
        
        isCreating = false
        dismiss()
    }
}
