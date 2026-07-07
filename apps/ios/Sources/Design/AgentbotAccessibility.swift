import SwiftUI

extension Font {
    static func agentbot(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }
}

extension ContentSizeCategory {
    var isAccessibilitySize: Bool {
        self >= .accessibilityMedium
    }
}

struct AgentbotAccessibility {
    static func reduceMotion(_ action: @escaping () -> Void) -> some View {
        EmptyView()
    }
}

extension View {
    func agentbotAccessibility() -> some View {
        self
            .accessibilityElement(children: .combine)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
    
    func agentbotCard() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct AgentbotBadge: View {
    let text: String
    var color: Color = AgentbotBrand.accent
    
    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }
}

struct AgentbotStatusDot: View {
    let status: Status
    
    enum Status {
        case online, offline, warning, busy
        
        var color: Color {
            switch self {
            case .online: AgentbotBrand.ok
            case .offline: .secondary
            case .warning: AgentbotBrand.warn
            case .busy: AgentbotBrand.accent
            }
        }
        
        var label: String {
            switch self {
            case .online: "Online"
            case .offline: "Offline"
            case .warning: "Warning"
            case .busy: "Busy"
            }
        }
    }
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 8, height: 8)
            .accessibilityLabel(status.label)
    }
}

#Preview {
    VStack(spacing: 20) {
        AgentbotBadge(text: "PRO")
        AgentbotBadge(text: "NEW", color: .purple)
        AgentbotStatusDot(status: .online)
        AgentbotStatusDot(status: .offline)
        AgentbotStatusDot(status: .warning)
        AgentbotStatusDot(status: .busy)
    }
    .padding()
}
