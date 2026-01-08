import SwiftUI

/// Tooltip bubble component for tour steps with arrow pointing to target
struct TourTooltipView: View {
    let step: TourStep
    let stepNumber: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void

    private let accentColor = Color(hex: "667eea")
    private let arrowSize: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            // Arrow above (when tooltip is below target)
            if step.position == .below {
                arrowView(direction: .up)
            }

            HStack(spacing: 0) {
                // Arrow on left (when tooltip is to the right of target)
                if step.position == .right {
                    arrowView(direction: .left)
                }

                // Main tooltip content
                tooltipContent

                // Arrow on right (when tooltip is to the left of target)
                if step.position == .left {
                    arrowView(direction: .right)
                }
            }

            // Arrow below (when tooltip is above target)
            if step.position == .above {
                arrowView(direction: .down)
            }
        }
    }

    // MARK: - Tooltip Content

    private var tooltipContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(step.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Message
            Text(step.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Bottom row: step indicator and buttons
            HStack {
                // Step indicator
                Text("\(stepNumber) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Skip button
                Button("Skip") {
                    onSkip()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                // Next/Done button
                Button(stepNumber == totalSteps ? "Done" : "Next") {
                    onNext()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(accentColor)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        )
    }

    // MARK: - Arrow View

    private func arrowView(direction: ArrowDirection) -> some View {
        ArrowShape(direction: direction)
            .fill(Color(.systemBackground))
            .frame(
                width: direction.isVertical ? arrowSize * 2 : arrowSize,
                height: direction.isVertical ? arrowSize : arrowSize * 2
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: direction == .up ? -2 : 2)
    }
}

// MARK: - Arrow Direction

private enum ArrowDirection {
    case up, down, left, right

    var isVertical: Bool {
        self == .up || self == .down
    }
}

// MARK: - Arrow Shape

private struct ArrowShape: Shape {
    let direction: ArrowDirection

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch direction {
        case .up:
            // Triangle pointing up
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()

        case .down:
            // Triangle pointing down
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()

        case .left:
            // Triangle pointing left
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()

        case .right:
            // Triangle pointing right
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }

        return path
    }
}

#Preview("Arrow Below - Tooltip Above Target") {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()

        TourTooltipView(
            step: TourStep(
                targetId: "test",
                title: "Practice with Virtual Money",
                message: "Play video poker with adjustable stakes and get real-time strategy feedback.",
                position: .above
            ),
            stepNumber: 1,
            totalSteps: 3,
            onNext: {},
            onSkip: {}
        )
    }
}

#Preview("Arrow Above - Tooltip Below Target") {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()

        TourTooltipView(
            step: TourStep(
                targetId: "test",
                title: "Analyze Any Hand",
                message: "Enter any hand to see the optimal strategy and expected value.",
                position: .below
            ),
            stepNumber: 3,
            totalSteps: 3,
            onNext: {},
            onSkip: {}
        )
    }
}
