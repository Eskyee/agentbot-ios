import SwiftUI

enum AgentbotBrand {
    static let uiAccent = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 59 / 255.0, green: 130 / 255.0, blue: 246 / 255.0, alpha: 1)
            : UIColor(red: 37 / 255.0, green: 99 / 255.0, blue: 235 / 255.0, alpha: 1)
    }

    static let accent = Color(uiColor: Self.uiAccent)
    static let accentHot = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 96 / 255.0, green: 165 / 255.0, blue: 250 / 255.0, alpha: 1)
            : UIColor(red: 59 / 255.0, green: 130 / 255.0, blue: 246 / 255.0, alpha: 1)
    })
    static let danger = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 252 / 255.0, green: 165 / 255.0, blue: 165 / 255.0, alpha: 1)
            : UIColor(red: 185 / 255.0, green: 28 / 255.0, blue: 28 / 255.0, alpha: 1)
    })
    static let ok = Color(red: 34 / 255.0, green: 197 / 255.0, blue: 94 / 255.0)
    static let warn = Color(red: 245 / 255.0, green: 158 / 255.0, blue: 11 / 255.0)
    static let info = Color(red: 59 / 255.0, green: 130 / 255.0, blue: 246 / 255.0)
    static let graphite = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 20 / 255.0, green: 22 / 255.0, blue: 24 / 255.0, alpha: 1)
            : UIColor(red: 246 / 255.0, green: 247 / 255.0, blue: 249 / 255.0, alpha: 1)
    })
    static let graphiteElevated = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 36 / 255.0, blue: 39 / 255.0, alpha: 1)
            : UIColor.white
    })

    static var sheetBackground: LinearGradient {
        LinearGradient(
            colors: [
                graphite,
                graphiteElevated.opacity(0.96),
                Color(uiColor: .systemBackground),
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
