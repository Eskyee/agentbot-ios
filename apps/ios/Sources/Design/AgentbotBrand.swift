import SwiftUI

enum AppAppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "appearance.preference"

    static var launchArgumentPreference: AppAppearancePreference? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--agentbot-appearance") else {
            return nil
        }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return AppAppearancePreference(rawValue: arguments[valueIndex].lowercased())
    }

    var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AgentbotBrand {
    static let uiAccent = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 239 / 255.0, green: 68 / 255.0, blue: 68 / 255.0, alpha: 1)
            : UIColor(red: 220 / 255.0, green: 38 / 255.0, blue: 38 / 255.0, alpha: 1)
    }

    static let accent = Color(uiColor: Self.uiAccent)
    static let accentHot = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 252 / 255.0, green: 129 / 255.0, blue: 129 / 255.0, alpha: 1)
            : UIColor(red: 239 / 255.0, green: 68 / 255.0, blue: 68 / 255.0, alpha: 1)
    })
    static let danger = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 252 / 255.0, green: 165 / 255.0, blue: 165 / 255.0, alpha: 1)
            : UIColor(red: 185 / 255.0, green: 28 / 255.0, blue: 28 / 255.0, alpha: 1)
    })
    static let ok = Color(red: 34 / 255.0, green: 197 / 255.0, blue: 94 / 255.0)
    static let warn = Color(red: 245 / 255.0, green: 158 / 255.0, blue: 11 / 255.0)
    static let info = Color(red: 239 / 255.0, green: 68 / 255.0, blue: 68 / 255.0)
    static let graphite = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 10 / 255.0, green: 10 / 255.0, blue: 10 / 255.0, alpha: 1)
            : UIColor(red: 246 / 255.0, green: 247 / 255.0, blue: 249 / 255.0, alpha: 1)
    })
    static let graphiteElevated = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 20 / 255.0, green: 20 / 255.0, blue: 20 / 255.0, alpha: 1)
            : UIColor.white
    })

    static let brandBlack = Color(red: 0 / 255.0, green: 0 / 255.0, blue: 0 / 255.0)
    static let brandWhite = Color(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0)

    static var sheetBackground: LinearGradient {
        LinearGradient(
            colors: [
                brandBlack,
                graphite,
                graphiteElevated.opacity(0.96),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }
}

extension View {
    func agentbotSheetChrome() -> some View {
        self
            .tint(AgentbotBrand.accent)
            .background {
                AgentbotBrand.sheetBackground
                    .ignoresSafeArea()
            }
    }
}
