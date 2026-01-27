import Foundation

// MARK: - Review Queue Service

actor ReviewQueueService {
    static let shared = ReviewQueueService()

    private var reviewItemsCache: [String: ReviewItem] = [:]  // keyed by handKey
    private var reviewStatsCache: ReviewStats?

    private init() {
        // Load cached items on init
        Task {
            await loadCachedItems()
        }
    }

    // MARK: - Load Cached Items

    private func loadCachedItems() {
        if let data = UserDefaults.standard.data(forKey: "review_items"),
           let items = try? JSONDecoder().decode([ReviewItem].self, from: data) {
            for item in items {
                reviewItemsCache[item.handKey] = item
            }
        }

        if let data = UserDefaults.standard.data(forKey: "review_stats"),
           let stats = try? JSONDecoder().decode(ReviewStats.self, from: data) {
            reviewStatsCache = stats
        }
    }

    private func saveCachedItems() {
        let items = Array(reviewItemsCache.values)
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "review_items")
        }

        if let stats = reviewStatsCache,
           let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "review_stats")
        }
    }

    // MARK: - Add Mistake to Queue

    /// Add a mistake to the review queue
    func addMistake(
        handKey: String,
        cards: [String],
        category: String,
        paytableId: String,
        correctHold: [Int],
        evLost: Double
    ) async {
        if var existing = reviewItemsCache[handKey] {
            // Update existing item
            existing.mistakeCount += 1
            existing.totalEvLost += evLost
            // Reset SM-2 state since they got it wrong again
            existing.easeFactor = max(1.3, existing.easeFactor - 0.2)
            existing.intervalDays = 1
            existing.nextReviewAt = Date()
            reviewItemsCache[handKey] = existing
        } else {
            // Create new item
            let item = ReviewItem.create(
                handKey: handKey,
                cards: cards,
                category: category,
                paytableId: paytableId,
                correctHold: correctHold,
                mistakeCount: 1,
                totalEvLost: evLost
            )
            reviewItemsCache[handKey] = item
        }

        saveCachedItems()
    }

    // MARK: - Get Review Queue

    /// Get items due for review, sorted by priority
    func getDueItems(paytableId: String? = nil, limit: Int = 20) async -> [ReviewItem] {
        var items = Array(reviewItemsCache.values)

        // Filter by paytable if specified
        if let paytableId = paytableId {
            items = items.filter { $0.paytableId == paytableId }
        }

        // Filter to due items
        items = items.filter { $0.isDue }

        // Sort by priority (highest first)
        items.sort { $0.priorityScore > $1.priorityScore }

        // Limit results
        return Array(items.prefix(limit))
    }

    /// Get all items in the queue (not just due)
    func getAllItems(paytableId: String? = nil) async -> [ReviewItem] {
        var items = Array(reviewItemsCache.values)

        if let paytableId = paytableId {
            items = items.filter { $0.paytableId == paytableId }
        }

        return items.sorted { $0.priorityScore > $1.priorityScore }
    }

    /// Get count of items due for review
    func getDueCount(paytableId: String? = nil) async -> Int {
        await getDueItems(paytableId: paytableId, limit: Int.max).count
    }

    // MARK: - Record Review Result

    /// Record the result of reviewing an item
    func recordReview(handKey: String, wasCorrect: Bool) async {
        guard var item = reviewItemsCache[handKey] else { return }

        // Convert to SM-2 quality rating
        let quality = wasCorrect ? 4 : 2  // 4 = good, 2 = wrong
        item.updateSM2(quality: quality)

        reviewItemsCache[handKey] = item

        // Update stats
        var stats = reviewStatsCache ?? ReviewStats.empty
        stats.totalReviews += 1
        if wasCorrect {
            stats.correctReviews += 1
        }
        stats.lastReviewDate = Date()
        stats.itemsInQueue = reviewItemsCache.count
        stats.itemsMastered = reviewItemsCache.values.filter { $0.intervalDays > 30 }.count
        reviewStatsCache = stats

        saveCachedItems()
    }

    // MARK: - Remove Mastered Item

    /// Remove an item that has been fully mastered (optional cleanup)
    func removeItem(handKey: String) async {
        reviewItemsCache.removeValue(forKey: handKey)
        saveCachedItems()
    }

    // MARK: - Get Stats

    /// Get review queue statistics
    func getStats() async -> ReviewStats {
        var stats = reviewStatsCache ?? ReviewStats.empty
        stats.itemsInQueue = reviewItemsCache.count
        stats.itemsMastered = reviewItemsCache.values.filter { $0.intervalDays > 30 }.count
        return stats
    }

    // MARK: - Clear Queue (for testing)

    /// Clear all items from the queue
    func clearQueue() async {
        reviewItemsCache.removeAll()
        reviewStatsCache = ReviewStats.empty
        UserDefaults.standard.removeObject(forKey: "review_items")
        UserDefaults.standard.removeObject(forKey: "review_stats")
    }
}
