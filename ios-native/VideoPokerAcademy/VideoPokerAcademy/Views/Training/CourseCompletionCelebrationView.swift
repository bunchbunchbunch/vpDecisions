import SwiftUI

struct CourseCompletionCelebrationView: View {
    @Binding var isPresented: Bool
    @State private var showCard = false
    @State private var particlesStarted = false

    private let particles: [CelebrationParticle] = (0..<40).map { _ in
        CelebrationParticle()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Particle rain layer
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for particle in particles {
                        guard particlesStarted else { continue }
                        let elapsed = now - particle.startOffset
                        let cycleDuration = Double(particle.fallDuration)
                        let progress = (elapsed.truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration

                        let x = particle.xFraction * size.width
                            + sin(elapsed * particle.wobbleSpeed) * particle.wobbleAmount
                        let y = -30 + progress * (size.height + 60)
                        let rotation = Angle.degrees(elapsed * particle.rotationSpeed)

                        var contextCopy = context
                        contextCopy.translateBy(x: x, y: y)
                        contextCopy.rotate(by: rotation)

                        let text = Text(particle.symbol)
                            .font(.system(size: particle.size))
                        contextCopy.draw(text, at: .zero)
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Center congratulations card
            VStack(spacing: 20) {
                Text("🏆")
                    .font(.system(size: 64))

                Text("Course Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("You've mastered\n9/6 Jacks or Better")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isPresented = false
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppTheme.Gradients.mintButton)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusButton))
                }
                .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .scaleEffect(showCard ? 1.0 : 0.5)
            .opacity(showCard ? 1.0 : 0.0)
        }
        .onAppear {
            particlesStarted = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCard = true
            }
        }
    }
}

// MARK: - Particle Model

private struct CelebrationParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let xFraction: CGFloat
    let fallDuration: CGFloat
    let rotationSpeed: Double
    let size: CGFloat
    let wobbleSpeed: Double
    let wobbleAmount: CGFloat
    let startOffset: TimeInterval

    private static let symbols = ["♠️", "♥️", "♦️", "♣️", "🪙", "🎰"]

    init() {
        symbol = Self.symbols.randomElement()!
        xFraction = CGFloat.random(in: 0.05...0.95)
        fallDuration = CGFloat.random(in: 3.0...6.0)
        rotationSpeed = Double.random(in: 20...120)
        size = CGFloat.random(in: 16...30)
        wobbleSpeed = Double.random(in: 1.0...3.0)
        wobbleAmount = CGFloat.random(in: 10...30)
        startOffset = TimeInterval.random(in: -10...0)
    }
}
