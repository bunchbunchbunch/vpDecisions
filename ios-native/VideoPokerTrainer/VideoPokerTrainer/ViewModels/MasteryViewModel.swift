import Foundation
import SwiftUI

@MainActor
class MasteryViewModel: ObservableObject {
    @Published var scores: [MasteryScore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let paytableId: String
    private let spacedRepetition = SpacedRepetitionService.shared

    init(paytableId: String) {
        self.paytableId = paytableId
    }

    var overallMastery: Double {
        spacedRepetition.calculateOverallMastery(scores: scores)
    }

    var masteryLevel: String {
        spacedRepetition.getMasteryLevel(percentage: overallMastery)
    }

    var totalAttempts: Int {
        scores.reduce(0) { $0 + $1.totalAttempts }
    }

    var sortedCategories: [MasteryScore] {
        spacedRepetition.getCategoriesByPriority(scores: scores)
    }

    var weakCategories: [HandCategory] {
        spacedRepetition.getWeakCategories(scores: scores)
    }

    var masteryColor: Color {
        switch overallMastery {
        case 0..<20: return Color(hex: "e74c3c")
        case 20..<40: return Color(hex: "e67e22")
        case 40..<60: return Color(hex: "f1c40f")
        case 60..<80: return Color(hex: "3498db")
        case 80..<95: return Color(hex: "27ae60")
        default: return Color(hex: "9b59b6")
        }
    }

    func loadScores() async {
        guard let user = SupabaseService.shared.currentUser else { return }

        isLoading = true
        errorMessage = nil

        do {
            scores = try await SupabaseService.shared.getMasteryScores(
                userId: user.id,
                paytableId: paytableId
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func scoreForCategory(_ category: HandCategory) -> MasteryScore? {
        scores.first { $0.category == category.rawValue }
    }
}
