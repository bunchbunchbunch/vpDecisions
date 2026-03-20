import Foundation
import SwiftUI

/// Identifies each product tour in the app
enum TourId: String, CaseIterable, Codable {
    case home = "home"
    case playStart = "playStart"
    case playGame = "playGame"
    case quizStart = "quizStart"
    case quizPlay = "quizPlay"
    case analyzer = "analyzer"

    var displayName: String {
        switch self {
        case .home: return "Home Screen"
        case .playStart: return "Play Setup"
        case .playGame: return "Play Mode"
        case .quizStart: return "Quiz Setup"
        case .quizPlay: return "Quiz Mode"
        case .analyzer: return "Hand Analyzer"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .playStart: return "gearshape.fill"
        case .playGame: return "suit.spade.fill"
        case .quizStart: return "slider.horizontal.3"
        case .quizPlay: return "target"
        case .analyzer: return "magnifyingglass"
        }
    }
}

/// Position of the tooltip relative to the target element
enum TooltipPosition {
    case above
    case below
    case left
    case right
    case center

    /// Calculate tooltip offset from target frame
    func offset(targetFrame: CGRect, tooltipSize: CGSize, screenSize: CGSize) -> CGPoint {
        let padding: CGFloat = 12
        let targetCenter = CGPoint(x: targetFrame.midX, y: targetFrame.midY)

        switch self {
        case .above:
            return CGPoint(
                x: clampX(targetCenter.x - tooltipSize.width / 2, tooltipSize: tooltipSize, screenSize: screenSize),
                y: targetFrame.minY - tooltipSize.height - padding
            )
        case .below:
            return CGPoint(
                x: clampX(targetCenter.x - tooltipSize.width / 2, tooltipSize: tooltipSize, screenSize: screenSize),
                y: targetFrame.maxY + padding
            )
        case .left:
            return CGPoint(
                x: targetFrame.minX - tooltipSize.width - padding,
                y: clampY(targetCenter.y - tooltipSize.height / 2, tooltipSize: tooltipSize, screenSize: screenSize)
            )
        case .right:
            return CGPoint(
                x: targetFrame.maxX + padding,
                y: clampY(targetCenter.y - tooltipSize.height / 2, tooltipSize: tooltipSize, screenSize: screenSize)
            )
        case .center:
            return CGPoint(
                x: (screenSize.width - tooltipSize.width) / 2,
                y: (screenSize.height - tooltipSize.height) / 2
            )
        }
    }

    private func clampX(_ x: CGFloat, tooltipSize: CGSize, screenSize: CGSize) -> CGFloat {
        let padding: CGFloat = 16
        return max(padding, min(x, screenSize.width - tooltipSize.width - padding))
    }

    private func clampY(_ y: CGFloat, tooltipSize: CGSize, screenSize: CGSize) -> CGFloat {
        let padding: CGFloat = 16
        return max(padding, min(y, screenSize.height - tooltipSize.height - padding))
    }
}

/// A single step in a product tour
struct TourStep: Identifiable {
    let id = UUID()
    let targetId: String
    let title: String
    let message: String
    let position: TooltipPosition
    let spotlightPadding: CGFloat
    let cornerRadius: CGFloat

    init(
        targetId: String,
        title: String,
        message: String,
        position: TooltipPosition = .below,
        spotlightPadding: CGFloat = 8,
        cornerRadius: CGFloat = 12
    ) {
        self.targetId = targetId
        self.title = title
        self.message = message
        self.position = position
        self.spotlightPadding = spotlightPadding
        self.cornerRadius = cornerRadius
    }
}

/// Preference key for collecting tour target frames
struct TourTargetPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
