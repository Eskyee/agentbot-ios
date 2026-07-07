import SwiftUI
import UIKit

enum AgentbotHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    static func success() {
        notification(.success)
    }
    
    static func error() {
        notification(.error)
    }
    
    static func warning() {
        notification(.warning)
    }
    
    static func light() {
        impact(.light)
    }
    
    static func medium() {
        impact(.medium)
    }
    
    static func heavy() {
        impact(.heavy)
    }
    
    static func rigid() {
        impact(.rigid)
    }
    
    static func soft() {
        impact(.soft)
    }
}

extension View {
    func hapticOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            AgentbotHaptics.impact(style)
        }
    }
}
