import Foundation

@MainActor
class ReviewQueueViewModel: ObservableObject {
    @Published var reviewItems: [ReviewItem] = []
    @Published var currentIndex: Int = 0
    @Published var correctCount: Int = 0
    @Published var stats: ReviewStats?
    @Published var isLoading = true
    @Published var isPreparing = true
    @Published var preparationMessage = ""
    @Published var error: String?

    // Current item state
    @Published var selectedIndices: Set<Int> = []
    @Published var showFeedback: Bool = false
    @Published var lastAnswerCorrect: Bool = false

    private let paytableId: String
    private let maxItems: Int

    var currentItem: ReviewItem? {
        guard currentIndex < reviewItems.count else { return nil }
        return reviewItems[currentIndex]
    }

    var progress: Double {
        guard !reviewItems.isEmpty else { return 0 }
        return Double(currentIndex) / Double(reviewItems.count)
    }

    var isComplete: Bool {
        currentIndex >= reviewItems.count && !reviewItems.isEmpty
    }

    var hasItems: Bool {
        !reviewItems.isEmpty
    }

    var accuracy: Double {
        guard currentIndex > 0 else { return 0 }
        return Double(correctCount) / Double(currentIndex) * 100
    }

    init(paytableId: String = PayTable.jacksOrBetter96.id, maxItems: Int = 20) {
        self.paytableId = paytableId
        self.maxItems = maxItems
    }

    func load() async {
        isLoading = true
        isPreparing = true
        error = nil
        preparationMessage = "Loading review queue..."

        // Load due items
        reviewItems = await ReviewQueueService.shared.getDueItems(paytableId: paytableId, limit: maxItems)
        stats = await ReviewQueueService.shared.getStats()

        if reviewItems.isEmpty {
            isLoading = false
            isPreparing = false
            return
        }

        // Prepare paytable for lookups
        preparationMessage = "Loading strategy data..."
        let prepared = await StrategyService.shared.preparePaytable(paytableId: paytableId) { [weak self] status in
            Task { @MainActor in
                self?.preparationMessage = status.message
            }
        }

        if !prepared {
            error = "Could not load strategy data"
        }

        currentIndex = 0
        correctCount = 0
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
        guard let item = currentItem else { return }

        // Check if answer is correct
        let userHold = Array(selectedIndices).sorted()
        let correctHold = item.correctHold.sorted()

        lastAnswerCorrect = userHold == correctHold
        if lastAnswerCorrect {
            correctCount += 1
        }

        showFeedback = true

        // Record review result
        Task {
            await ReviewQueueService.shared.recordReview(handKey: item.handKey, wasCorrect: lastAnswerCorrect)
        }

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
        showFeedback = false
        selectedIndices = []
        currentIndex += 1

        if isComplete {
            // Refresh stats
            Task {
                stats = await ReviewQueueService.shared.getStats()
            }
        }
    }

    func restart() async {
        currentIndex = 0
        correctCount = 0
        selectedIndices = []
        showFeedback = false

        // Reload items
        reviewItems = await ReviewQueueService.shared.getDueItems(paytableId: paytableId, limit: maxItems)
    }
}
