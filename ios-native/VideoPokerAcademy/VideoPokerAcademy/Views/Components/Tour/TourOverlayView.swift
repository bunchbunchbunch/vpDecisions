import SwiftUI

/// Full-screen overlay for product tours with spotlight cutout
struct TourOverlayView: View {
    @ObservedObject private var tourManager = TourManager.shared
    @State private var tooltipSize: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if tourManager.isShowingTour, let step = tourManager.currentStep {
                    // Dimmed background with spotlight cutout
                    spotlightOverlay(step: step, screenSize: geometry.size)

                    // Tooltip
                    if let targetFrame = tourManager.currentTargetFrame {
                        tooltipView(step: step, targetFrame: targetFrame, screenSize: geometry.size)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.3), value: tourManager.isShowingTour)
            .animation(.easeOut(duration: 0.3), value: tourManager.currentStepIndex)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Spotlight Overlay

    @ViewBuilder
    private func spotlightOverlay(step: TourStep, screenSize: CGSize) -> some View {
        if let targetFrame = tourManager.currentTargetFrame {
            // Create spotlight effect with cutout
            SpotlightShape(
                targetFrame: targetFrame,
                padding: step.spotlightPadding,
                cornerRadius: step.cornerRadius
            )
            .fill(Color.black.opacity(0.6))
            .allowsHitTesting(false)
        } else {
            // No target frame yet, just show dimmed overlay
            Color.black.opacity(0.6)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Tooltip View

    @ViewBuilder
    private func tooltipView(step: TourStep, targetFrame: CGRect, screenSize: CGSize) -> some View {
        TourTooltipView(
            step: step,
            stepNumber: tourManager.currentStepIndex + 1,
            totalSteps: tourManager.totalSteps,
            onNext: {
                tourManager.nextStep()
            },
            onSkip: {
                tourManager.skipTour()
            }
        )
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { tooltipSize = geo.size }
                    .onChange(of: geo.size) { _, newSize in tooltipSize = newSize }
            }
        )
        .position(tooltipPosition(step: step, targetFrame: targetFrame, screenSize: screenSize))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Position Calculation

    private func tooltipPosition(step: TourStep, targetFrame: CGRect, screenSize: CGSize) -> CGPoint {
        let offset = step.position.offset(
            targetFrame: targetFrame,
            tooltipSize: tooltipSize,
            screenSize: screenSize
        )
        // Return center point for .position modifier
        return CGPoint(
            x: offset.x + tooltipSize.width / 2,
            y: offset.y + tooltipSize.height / 2
        )
    }
}

// MARK: - Spotlight Shape

/// Custom shape that fills the screen except for a rounded rectangle cutout
struct SpotlightShape: Shape {
    let targetFrame: CGRect
    let padding: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Full screen rectangle
        path.addRect(rect)

        // Spotlight cutout (with padding)
        let spotlightRect = targetFrame.insetBy(dx: -padding, dy: -padding)
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius + padding)
            .path(in: spotlightRect)

        // Subtract the spotlight from the full screen
        path.addPath(roundedRect)

        return path
    }
}

// MARK: - Tour Overlay Modifier

/// View modifier to add tour overlay to a view
struct TourOverlayModifier: ViewModifier {
    let tourId: TourId
    let isReady: Bool
    @ObservedObject private var tourManager = TourManager.shared
    @State private var viewId = UUID()
    @State private var registeredTargetIds: Set<String> = []
    @State private var hasTriggeredTour = false

    func body(content: Content) -> some View {
        ZStack {
            content
                .onPreferenceChange(TourTargetPreferenceKey.self) { frames in
                    for (id, frame) in frames {
                        tourManager.registerTarget(id, frame: frame)
                        registeredTargetIds.insert(id)
                    }
                }

            TourOverlayView()
                .allowsHitTesting(tourManager.isShowingTour)
        }
        .task(id: viewId) {
            // Wait for layout to complete
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                // Only start if ready (or if no ready condition was provided, isReady defaults to true)
                if isReady && !hasTriggeredTour {
                    hasTriggeredTour = true
                    tourManager.startTourIfNeeded(tourId)
                }
            }
        }
        .onChange(of: isReady) { _, newValue in
            // When isReady becomes true, start the tour after a short delay for layout
            if newValue && !hasTriggeredTour {
                hasTriggeredTour = true
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    await MainActor.run {
                        tourManager.startTourIfNeeded(tourId)
                    }
                }
            }
        }
        .onDisappear {
            // Only clear frames this view registered, not all frames
            for id in registeredTargetIds {
                tourManager.unregisterTarget(id)
            }
            registeredTargetIds.removeAll()
        }
    }
}

extension View {
    /// Add tour overlay to this view with automatic tour triggering
    func withTour(_ tourId: TourId) -> some View {
        modifier(TourOverlayModifier(tourId: tourId, isReady: true))
    }

    /// Add tour overlay that waits for a ready condition before triggering
    func withTour(_ tourId: TourId, isReady: Bool) -> some View {
        modifier(TourOverlayModifier(tourId: tourId, isReady: isReady))
    }
}

#Preview {
    ZStack {
        VStack(spacing: 20) {
            Text("Home Screen")
                .font(.largeTitle)

            Button("Play Mode") {}
                .tourTarget("playModeButton")
                .buttonStyle(.borderedProminent)

            Button("Quiz Mode") {}
                .tourTarget("quizModeButton")
                .buttonStyle(.bordered)

            Button("Analyzer") {}
                .tourTarget("analyzerButton")
                .buttonStyle(.bordered)
        }

        TourOverlayView()
    }
    .onAppear {
        TourManager.shared.startTour(.home)
        TourManager.shared.registerTarget("playModeButton", frame: CGRect(x: 100, y: 200, width: 200, height: 50))
    }
}
