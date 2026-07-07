import SwiftUI

struct AgentbotSplashView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            AgentbotBrand.graphite.ignoresSafeArea()
            
            VStack(spacing: 24) {
                AgentbotProMark(size: isAnimating ? 80 : 60, shadowRadius: isAnimating ? 20 : 10)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(showContent ? 1 : 0)
                
                if showContent {
                    VStack(spacing: 8) {
                        Text("Agentbot")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Your AI agent, always with you.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                isAnimating = true
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                showContent = true
            }
        }
    }
}

#Preview {
    AgentbotSplashView()
}
