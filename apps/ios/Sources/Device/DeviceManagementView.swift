import SwiftUI

struct DeviceManagementView: View {
    @State private var devices: [Device] = []
    @State private var isLoading = true
    
    struct Device: Identifiable, Codable {
        let id: String
        let name: String
        let type: DeviceType
        let status: String
        let lastSeen: Date?
        let osVersion: String?
        
        enum DeviceType: String, Codable {
            case iPhone, iPad, Mac, watch, unknown
            
            var icon: String {
                switch self {
                case .iPhone: return "iphone"
                case .iPad: return "ipad"
                case .Mac: return "laptopcomputer"
                case .watch: return "applewatch"
                case .unknown: return "questionmark.diamond"
                }
            }
        }
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading devices...")
            } else if devices.isEmpty {
                ContentUnavailableView(
                    "No Devices",
                    systemImage: "devices",
                    description: Text("Pair a device to get started.")
                )
            } else {
                ForEach(devices) { device in
                    HStack(spacing: 12) {
                        Image(systemName: device.type.icon)
                            .font(.title2)
                            .frame(width: 40)
                        VStack(alignment: .leading) {
                            Text(device.name).font(.headline)
                            HStack {
                                Text(device.status)
                                    .font(.caption)
                                    .foregroundStyle(device.status == "online" ? .green : .secondary)
                                if let os = device.osVersion {
                                    Text("\(os)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Devices")
        .refreshable { await loadDevices() }
        .task { await loadDevices() }
    }
    
    private func loadDevices() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/devices")
            devices = try JSONDecoder().decode([Device].self, from: data)
        } catch { devices = [] }
        isLoading = false
    }
}
