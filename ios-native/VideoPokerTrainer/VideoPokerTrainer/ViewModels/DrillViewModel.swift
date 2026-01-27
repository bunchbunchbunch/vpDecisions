import Foundation

@MainActor
class DrillViewModel: ObservableObject {
    @Published var drill: Drill?
    @Published var session: DrillSession?
    @Published var stats: DrillStats?
    @Published var isLoading = true
    @Published var isPreparing = true
    @Published var preparationMessage = ""
    @Published var error: String?

    // Current hand state
    @Published var selectedIndices: Set<Int> = []
    @Published var showFeedback: Bool = false
    @Published var lastAnswerCorrect: Bool = false
    @Published var currentStreak: Int = 0

    private let drillId: String
    private let paytableId: String

    var currentHand: DrillHand? {
        guard let session = session, session.currentIndex < session.hands.count else { return nil }
        return session.hands[session.currentIndex]
    }

    var progress: Double {
        guard let session = session, !session.hands.isEmpty else { return 0 }
        return Double(session.currentIndex) / Double(session.hands.count)
    }

    var isComplete: Bool {
        session?.isComplete ?? false
    }

    init(drillId: String, paytableId: String = PayTable.jacksOrBetter96.id) {
        self.drillId = drillId
        self.paytableId = paytableId
    }

    func load() async {
        isLoading = true
        isPreparing = true
        error = nil
        preparationMessage = "Preparing drill..."

        guard let loadedDrill = TrainingService.shared.drill(for: drillId) else {
            error = "Drill not found"
            isLoading = false
            isPreparing = false
            return
        }

        drill = loadedDrill
        stats = await TrainingService.shared.stats(for: drillId)

        // Prepare paytable
        preparationMessage = "Loading strategy data..."
        let prepared = await StrategyService.shared.preparePaytable(paytableId: paytableId) { [weak self] status in
            Task { @MainActor in
                self?.preparationMessage = status.message
            }
        }

        if !prepared {
            error = "Could not load strategy data"
            isLoading = false
            isPreparing = false
            return
        }

        // Generate drill hands
        preparationMessage = "Finding hands for drill..."
        let hands = await TrainingService.shared.generateDrillHands(
            drill: loadedDrill,
            paytableId: paytableId,
            count: loadedDrill.handsPerSession
        )

        if hands.isEmpty {
            error = "Could not generate drill hands"
            isLoading = false
            isPreparing = false
            return
        }

        session = DrillSession.start(drillId: drillId, paytableId: paytableId, hands: hands)
        currentStreak = 0

        isLoading = false
        isPreparing = false
    }

    func toggleCardSelection(_ index: Int) {
        guard !showFeedback else { return }
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    func submit() {
        guard let session = session, let currentHand = currentHand else { return }

        // Convert user selection to canonical order for comparison
        let userIndices = Array(selectedIndices).sorted()
        let canonicalUserIndices = currentHand.hand.originalIndicesToCanonical(userIndices)

        // Check if correct using strategy result
        lastAnswerCorrect = currentHand.strategyResult.isHoldTiedForBest(canonicalUserIndices)

        // Calculate EV lost if wrong
        var evLost: Double = 0
        if !lastAnswerCorrect {
            let userBitmask = Hand.bitmaskFromHoldIndices(canonicalUserIndices)
            if let userEv = currentHand.strategyResult.holdEvs[String(userBitmask)] {
                evLost = currentHand.strategyResult.bestEv - userEv
            }
            currentStreak = 0
        } else {
            currentStreak += 1
        }

        // Update session
        var updatedSession = session
        updatedSession.hands[session.currentIndex].userHold = userIndices
        updatedSession.hands[session.currentIndex].isCorrect = lastAnswerCorrect
        updatedSession.hands[session.currentIndex].evLost = evLost

        if lastAnswerCorrect {
            updatedSession.correctCount += 1
        }
        updatedSession.totalEvLost += evLost

        self.session = updatedSession

        showFeedback = true

        // Play audio feedback
        Task {
            if lastAnswerCorrect {
                AudioService.shared.play(.correct)
            } else {
                AudioService.shared.play(.incorrect)
            }
        }
    }

    func next() {
        guard var session = session else { return }

        showFeedback = false
        selectedIndices = []
        session.currentIndex += 1

        if session.currentIndex >= session.hands.count {
            session.completedAt = Date()
            self.session = session
            completeDrill()
        } else {
            self.session = session
        }
    }

    private func completeDrill() {
        guard let session = session else { return }

        Task {
            await TrainingService.shared.recordDrillSession(
                drillId: drillId,
                correct: session.correctCount,
                total: session.hands.count,
                evLost: session.totalEvLost
            )

            // Refresh stats
            stats = await TrainingService.shared.stats(for: drillId)
        }
    }

    func restart() async {
        guard let drill = drill else { return }

        isPreparing = true
        preparationMessage = "Generating new hands..."

        let hands = await TrainingService.shared.generateDrillHands(
            drill: drill,
            paytableId: paytableId,
            count: drill.handsPerSession
        )

        session = DrillSession.start(drillId: drillId, paytableId: paytableId, hands: hands)
        selectedIndices = []
        showFeedback = false
        currentStreak = 0

        isPreparing = false
    }
}
