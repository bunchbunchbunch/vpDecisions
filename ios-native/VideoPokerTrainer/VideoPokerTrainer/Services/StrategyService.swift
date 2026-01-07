import Foundation

actor StrategyService {
    static let shared = StrategyService()

    private var cache: [String: StrategyResult] = [:]
    private let maxCacheSize = 100

    /// Track loading tasks so multiple callers can await the same load operation
    private var loadingTasks: [String: Task<Void, Never>] = [:]

    /// Bundled paytables available for lazy loading
    private let bundledPaytables: [String: (filename: String, displayName: String)] = [
        "jacks-or-better-9-6": ("strategy_jacks_or_better_9_6", "Jacks or Better 9/6"),
        "double-double-bonus-9-6": ("strategy_double_double_bonus_9_6", "Double Double Bonus 9/6"),
        "triple-double-bonus-9-6": ("strategy_triple_double_bonus_9_6", "Triple Double Bonus 9/6"),
        "deuces-wild-nsud": ("strategy_deuces_wild_nsud", "Deuces Wild NSUD"),
    ]

    private init() {}

    /// Lookup optimal strategy for a hand
    /// Priority: 1) Memory cache, 2) Local SQLite (lazy-load if needed), 3) Supabase (online)
    func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult? {
        let key = "\(paytableId):\(hand.canonicalKey)"

        // 1. Check memory cache first
        if let cached = cache[key] {
            return cached
        }

        // 2. Ensure paytable is loaded (lazy loading from bundle if needed)
        await ensurePaytableLoaded(paytableId: paytableId)

        // 3. Try local SQLite database
        if let localResult = await LocalStrategyStore.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: localResult)
            return localResult
        }

        // 4. Fall back to Supabase (online lookup)
        if let supabaseResult = try await SupabaseService.shared.lookupStrategy(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: supabaseResult)
            return supabaseResult
        }

        return nil
    }

    /// Ensure a paytable's strategy data is loaded into SQLite
    /// This handles lazy loading of bundled compressed files on first use
    private func ensurePaytableLoaded(paytableId: String) async {
        // Check if already loaded in SQLite
        let existingCount = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        if existingCount > 0 {
            return  // Already loaded
        }

        // Check if another task is already loading this paytable
        if let existingTask = loadingTasks[paytableId] {
            // Wait for the existing load to complete
            await existingTask.value
            return
        }

        // Check if this is a bundled paytable
        guard let config = bundledPaytables[paytableId] else {
            return  // Not a bundled paytable, will fall back to Supabase
        }

        // Create a loading task that others can await
        let loadTask = Task<Void, Never> {
            await performLoad(paytableId: paytableId, config: config)
        }

        loadingTasks[paytableId] = loadTask

        // Wait for our own task to complete
        await loadTask.value

        // Clean up
        loadingTasks.removeValue(forKey: paytableId)
    }

    /// Actually perform the load operation
    private func performLoad(paytableId: String, config: (filename: String, displayName: String)) async {
        // Find the bundled file (try compressed first)
        var url = Bundle.main.url(forResource: config.filename, withExtension: "json.gz")
        if url == nil {
            url = Bundle.main.url(forResource: config.filename, withExtension: "json")
        }

        guard let fileUrl = url else {
            NSLog("⚠️ Could not find \(config.filename).json.gz or .json in bundle")
            return
        }

        // Load and decompress on-demand
        NSLog("📦 Loading \(config.displayName) on first use...")
        do {
            let count = try await LocalStrategyStore.shared.importFromJSON(
                url: fileUrl,
                paytableId: paytableId,
                displayName: config.displayName,
                isBundled: true
            )
            NSLog("📦 Loaded \(config.displayName): \(count) hands")
        } catch {
            NSLog("❌ Error loading \(config.filename): \(error)")
        }
    }

    /// Check if a paytable has offline data available (either loaded or bundled)
    func hasOfflineData(paytableId: String) async -> Bool {
        // Check if already in SQLite
        if await LocalStrategyStore.shared.hasLocalData(paytableId: paytableId) {
            return true
        }
        // Check if bundled (can be loaded on-demand)
        return bundledPaytables[paytableId] != nil
    }

    /// Check if a paytable is bundled with the app
    func isBundledPaytable(paytableId: String) -> Bool {
        return bundledPaytables[paytableId] != nil
    }

    /// Prepare a paytable for use - decompresses and loads into SQLite if needed
    /// Call this before starting a game to ensure smooth gameplay
    /// Returns true if ready, false if not a bundled paytable or failed
    func preparePaytable(paytableId: String) async -> Bool {
        // Check if already loaded
        let existingCount = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        if existingCount > 0 {
            return true  // Already ready
        }

        // Check if this is a bundled paytable
        guard bundledPaytables[paytableId] != nil else {
            return true  // Not bundled, will use Supabase - consider ready
        }

        // Load it (this will wait for completion)
        await ensurePaytableLoaded(paytableId: paytableId)

        // Verify it loaded
        let finalCount = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        return finalCount > 0
    }

    /// Check if a paytable needs to be loaded (not yet in SQLite but is bundled)
    func paytableNeedsLoading(paytableId: String) async -> Bool {
        // If not bundled, no loading needed
        guard bundledPaytables[paytableId] != nil else {
            return false
        }
        // Check if already in SQLite
        let count = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        return count == 0
    }

    /// Get list of paytables with offline data
    func getOfflinePaytables() async -> [PaytableMetadata] {
        return await LocalStrategyStore.shared.getAvailablePaytables()
    }

    /// Get local database storage size
    func getStorageSize() async -> Int64 {
        return await LocalStrategyStore.shared.getDatabaseSize()
    }

    // MARK: - Cache Management

    private func cacheResult(key: String, result: StrategyResult) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries (simple approach: clear half)
            let keysToRemove = Array(cache.keys.prefix(maxCacheSize / 2))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
        cache[key] = result
    }

    /// Clear the memory cache
    func clearCache() {
        cache.removeAll()
    }
}
