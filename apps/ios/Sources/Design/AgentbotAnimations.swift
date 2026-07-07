import SwiftUI

extension Animation {
    static let agentbotSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let agentbotEase = Animation.easeInOut(duration: 0.3)
    static let agentbotQuick = Animation.easeOut(duration: 0.15)
}

struct AgentbotShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: phase - 0.3),
                            .init(color: .white.opacity(0.3), location: phase),
                            .init(color: .clear, location: phase + 0.3),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.sourceAtop)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1.3
                        }
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(AgentbotShimmer())
    }
}

struct AgentbotPulse: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(AgentbotPulse())
    }
}

struct AgentbotBounce: ViewModifier {
    @State private var isBouncing = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isBouncing ? -5 : 0)
            .animation(.interpolatingSpring(stiffness: 300, damping: 10).repeatForever(), value: isBouncing)
            .onAppear {
                isBouncing = true
            }
    }
}

extension View {
    func bounce() -> some View {
        modifier(AgentbotBounce())
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Shimmer")
            .shimmer()
        
        Text("Pulse")
            .pulse()
        
        Text("Bounce")
            .bounce()
    }
    .padding()
}
