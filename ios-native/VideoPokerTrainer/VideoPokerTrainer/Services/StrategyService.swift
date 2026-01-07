import Foundation

actor StrategyService {
    static let shared = StrategyService()

    private var cache: [String: StrategyResult] = [:]
    private let maxCacheSize = 100

    /// Track loading tasks so multiple callers can await the same load operation
    private var loadingTasks: [String: Task<Bool, Never>] = [:]

    /// Supabase Storage base URL for strategy files
    private let storageBaseURL = "https://ctqefgdvqiaiumtmcjdz.supabase.co/storage/v1/object/public/strategies"

    /// Bundled paytables available for lazy loading (included with app)
    private let bundledPaytables: [String: (filename: String, displayName: String)] = [
        "jacks-or-better-9-6": ("strategy_jacks_or_better_9_6", "Jacks or Better 9/6"),
        "double-double-bonus-9-6": ("strategy_double_double_bonus_9_6", "Double Double Bonus 9/6"),
        "triple-double-bonus-9-6": ("strategy_triple_double_bonus_9_6", "Triple Double Bonus 9/6"),
        "deuces-wild-nsud": ("strategy_deuces_wild_nsud", "Deuces Wild NSUD"),
    ]

    /// Downloadable paytables (available from Supabase Storage)
    private let downloadablePaytables: [String: (filename: String, displayName: String)] = [
        "bonus-poker-8-5": ("strategy_bonus_poker_8_5", "Bonus Poker 8/5"),
        "double-bonus-10-7": ("strategy_double_bonus_10_7", "Double Bonus 10/7"),
        "deuces-wild-full-pay": ("strategy_deuces_wild_full_pay", "Deuces Wild Full Pay"),
    ]

    private init() {}

    /// Lookup optimal strategy for a hand
    /// All lookups go through local SQLite - paytables must be downloaded first
    func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult? {
        let key = "\(paytableId):\(hand.canonicalKey)"

        // 1. Check memory cache first
        if let cached = cache[key] {
            return cached
        }

        // 2. Ensure paytable is loaded (lazy loading from bundle or download if needed)
        _ = await ensurePaytableLoaded(paytableId: paytableId)

        // 3. Lookup from local SQLite database
        if let localResult = await LocalStrategyStore.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: localResult)
            return localResult
        }

        // No fallback to Supabase - all strategies must be downloaded first
        NSLog("⚠️ No local strategy found for %@ / %@", paytableId, hand.canonicalKey)
        return nil
    }

    /// Ensure a paytable's strategy data is loaded into SQLite
    /// This handles lazy loading of bundled files and downloading non-bundled files
    private func ensurePaytableLoaded(paytableId: String) async -> Bool {
        // Check if already loaded in SQLite
        let existingCount = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        if existingCount > 0 {
            return true  // Already loaded
        }

        // Check if another task is already loading this paytable
        if let existingTask = loadingTasks[paytableId] {
            // Wait for the existing load to complete
            return await existingTask.value
        }

        // Determine if bundled or downloadable
        let isBundled = bundledPaytables[paytableId] != nil
        let isDownloadable = downloadablePaytables[paytableId] != nil

        guard isBundled || isDownloadable else {
            NSLog("⚠️ Paytable %@ is neither bundled nor downloadable", paytableId)
            return false
        }

        // Create a loading task that others can await
        let loadTask = Task<Bool, Never> {
            if isBundled {
                return await performBundledLoad(paytableId: paytableId)
            } else {
                return await performDownload(paytableId: paytableId)
            }
        }

        loadingTasks[paytableId] = loadTask

        // Wait for our own task to complete
        let success = await loadTask.value

        // Clean up
        loadingTasks.removeValue(forKey: paytableId)

        return success
    }

    /// Load a bundled paytable from app bundle
    private func performBundledLoad(paytableId: String) async -> Bool {
        guard let config = bundledPaytables[paytableId] else { return false }

        // Find the bundled file (try compressed first)
        var url = Bundle.main.url(forResource: config.filename, withExtension: "json.gz")
        if url == nil {
            url = Bundle.main.url(forResource: config.filename, withExtension: "json")
        }

        guard let fileUrl = url else {
            NSLog("⚠️ Could not find \(config.filename).json.gz or .json in bundle")
            return false
        }

        // Load and decompress on-demand
        NSLog("📦 Loading \(config.displayName) from bundle...")
        do {
            let count = try await LocalStrategyStore.shared.importFromJSON(
                url: fileUrl,
                paytableId: paytableId,
                displayName: config.displayName,
                isBundled: true
            )
            NSLog("📦 Loaded \(config.displayName): \(count) hands")
            return count > 0
        } catch {
            NSLog("❌ Error loading \(config.filename): \(error)")
            return false
        }
    }

    /// Download a paytable from Supabase Storage
    private func performDownload(paytableId: String) async -> Bool {
        guard let config = downloadablePaytables[paytableId] else { return false }

        let urlString = "\(storageBaseURL)/\(config.filename).json.gz"
        guard let url = URL(string: urlString) else {
            NSLog("❌ Invalid download URL: \(urlString)")
            return false
        }

        NSLog("⬇️ Downloading \(config.displayName) from Supabase Storage...")

        do {
            // Download the file
            let (tempURL, response) = try await URLSession.shared.download(from: url)

            // Check response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                NSLog("❌ Download failed with status \(httpResponse.statusCode)")
                return false
            }

            // Import from the downloaded file
            let count = try await LocalStrategyStore.shared.importFromJSON(
                url: tempURL,
                paytableId: paytableId,
                displayName: config.displayName,
                isBundled: false
            )

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)

            NSLog("⬇️ Downloaded \(config.displayName): \(count) hands")
            return count > 0
        } catch {
            NSLog("❌ Error downloading \(config.filename): \(error)")
            return false
        }
    }

    /// Download a specific paytable (for manual download from UI)
    /// Returns true if download succeeded
    func downloadPaytable(paytableId: String) async -> Bool {
        // Check if already loaded
        let existingCount = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        if existingCount > 0 {
            NSLog("ℹ️ Paytable %@ is already downloaded", paytableId)
            return true
        }

        // Perform download
        return await ensurePaytableLoaded(paytableId: paytableId)
    }

    /// Check if a paytable has offline data available (either loaded, bundled, or downloadable)
    func hasOfflineData(paytableId: String) async -> Bool {
        // Check if already in SQLite
        if await LocalStrategyStore.shared.hasLocalData(paytableId: paytableId) {
            return true
        }
        // Check if bundled or downloadable (can be loaded on-demand)
        return bundledPaytables[paytableId] != nil || downloadablePaytables[paytableId] != nil
    }

    /// Check if a paytable is bundled with the app
    func isBundledPaytable(paytableId: String) -> Bool {
        return bundledPaytables[paytableId] != nil
    }

    /// Check if a paytable is downloadable from server
    func isDownloadablePaytable(paytableId: String) -> Bool {
        return downloadablePaytables[paytableId] != nil
    }

    /// Prepare a paytable for use - loads from bundle or downloads from server
    /// Call this before starting a game to ensure smooth gameplay
    /// Returns true if ready, false if failed
    func preparePaytable(paytableId: String) async -> Bool {
        // Check if already loaded
        let existingCount = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        if existingCount > 0 {
            return true  // Already ready
        }

        // Check if this paytable can be loaded (bundled or downloadable)
        let isBundled = bundledPaytables[paytableId] != nil
        let isDownloadable = downloadablePaytables[paytableId] != nil

        guard isBundled || isDownloadable else {
            NSLog("⚠️ Paytable %@ cannot be prepared - not bundled or downloadable", paytableId)
            return false
        }

        // Load/download it (this will wait for completion)
        return await ensurePaytableLoaded(paytableId: paytableId)
    }

    /// Check if a paytable needs to be loaded (not yet in SQLite but is available)
    func paytableNeedsLoading(paytableId: String) async -> Bool {
        // If neither bundled nor downloadable, no loading needed/possible
        let isBundled = bundledPaytables[paytableId] != nil
        let isDownloadable = downloadablePaytables[paytableId] != nil

        guard isBundled || isDownloadable else {
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
