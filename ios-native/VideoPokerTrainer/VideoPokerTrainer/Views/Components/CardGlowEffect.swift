import SwiftUI

struct CardGlowEffect: ViewModifier {
    let isGlowing: Bool
    @State private var pulseOpacity: Double = 0.4
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isGlowing ? Color(hex: "FFD700").opacity(pulseOpacity) : .clear,
                radius: isGlowing ? 20 : 0
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color(hex: "FFD700").opacity(isGlowing ? pulseOpacity : 0),
                        lineWidth: 3
                    )
            )
            .scaleEffect(scale)
            .onAppear {
                if isGlowing {
                    startPulsing()
                }
            }
            .onChange(of: isGlowing) { newValue in
                if newValue {
                    startPulsing()
                } else {
                    stopPulsing()
                }
            }
    }

    private func startPulsing() {
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatCount(4, autoreverses: true)
        ) {
            pulseOpacity = 1.0
            scale = 1.05
        }

        // Return to normal after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                pulseOpacity = 0.4
                scale = 1.0
            }
        }
    }

    private func stopPulsing() {
        pulseOpacity = 0.4
        scale = 1.0
    }
}

extension View {
    func cardGlow(isGlowing: Bool) -> some View {
        modifier(CardGlowEffect(isGlowing: isGlowing))
    }
}

#Preview {
    VStack(spacing: 20) {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white)
            .frame(width: 60, height: 90)
            .cardGlow(isGlowing: true)

        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white)
            .frame(width: 60, height: 90)
            .cardGlow(isGlowing: false)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
