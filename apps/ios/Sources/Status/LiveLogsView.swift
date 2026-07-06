import SwiftUI

struct LiveLogsView: View {
    @State private var logs: [LogEntry] = []
    @State private var isLoading = true
    @State private var autoScroll = true
    @State private var filterLevel: LogLevel = .all

    struct LogEntry: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let level: LogLevel
        let source: String
        let message: String

        init(id: UUID = UUID(), timestamp: Date = Date(), level: LogLevel, source: String, message: String) {
            self.id = id
            self.timestamp = timestamp
            self.level = level
            self.source = source
            self.message = message
        }
    }

    enum LogLevel: String, Codable, CaseIterable, Identifiable {
        case debug, info, warn, error, all
        
        var id: String { rawValue }

        var color: Color {
            switch self {
            case .debug: return .gray
            case .info: return .blue
            case .warn: return .orange
            case .error: return .red
            case .all: return .primary
            }
        }

        var icon: String {
            switch self {
            case .debug: return "bug"
            case .info: return "info.circle"
            case .warn: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .all: return "list.bullet"
            }
        }
    }

    var filteredLogs: [LogEntry] {
        if filterLevel == .all { return logs }
        return logs.filter { $0.level == filterLevel }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Filter", selection: $filterLevel) {
                    ForEach(LogLevel.allCases) { level in
                        Label(level.rawValue.capitalized, systemImage: level.icon)
                            .tag(level)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if logs.isEmpty {
                ContentUnavailableView(
                    "No Logs",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Logs will appear here when connected.")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredLogs) { log in
                                LogRow(log: log)
                                    .id(log.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: filteredLogs.count) {
                        if autoScroll, let lastLog = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Live Logs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    logs.removeAll()
                }
            }
        }
        .task {
            await loadLogs()
        }
    }

    private func loadLogs() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/logs?limit=100")
            logs = try JSONDecoder().decode([LogEntry].self, from: data)
        } catch {
            logs = []
        }
        isLoading = false
    }
}

private struct LogRow: View {
    let log: LiveLogsView.LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: log.level.icon)
                .foregroundStyle(log.level.color)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(log.source)
                        .font(.caption.bold())
                    Text(log.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(log.message)
                    .font(.caption)
                    .textSelection(.enabled)
            }
        }
    }
}
