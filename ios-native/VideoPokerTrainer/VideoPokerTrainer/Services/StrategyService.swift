import Foundation

/// Loading status for paytable preparation
enum PaytableLoadingStatus: Equatable {
    case checking
    case downloading
    case importing
    case ready
    case failed(String)

    var displayMessage: String {
        switch self {
        case .checking:
            return "Checking strategy data..."
        case .downloading:
            return "Downloading strategy..."
        case .importing:
            return "Importing strategy data..."
        case .ready:
            return "Ready"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }
}

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
        // Jacks or Better variants
        "jacks-or-better-9-5": ("strategy_jacks_or_better_9_5", "Jacks or Better 9/5"),
        "jacks-or-better-8-6": ("strategy_jacks_or_better_8_6", "Jacks or Better 8/6"),
        "jacks-or-better-8-5": ("strategy_jacks_or_better_8_5", "Jacks or Better 8/5"),
        "jacks-or-better-7-5": ("strategy_jacks_or_better_7_5", "Jacks or Better 7/5"),
        "jacks-or-better-6-5": ("strategy_jacks_or_better_6_5", "Jacks or Better 6/5"),
        "jacks-or-better-9-6-90": ("strategy_jacks_or_better_9_6_90", "Jacks or Better 9/6/90 (100%)"),
        "jacks-or-better-9-6-940": ("strategy_jacks_or_better_9_6_940", "Jacks or Better 9/6 RF940"),
        // Bonus Poker
        "bonus-poker-8-5": ("strategy_bonus_poker_8_5", "Bonus Poker 8/5"),
        // Double Bonus
        "double-bonus-10-7": ("strategy_double_bonus_10_7", "Double Bonus 10/7"),
        // Deuces Wild
        "deuces-wild-full-pay": ("strategy_deuces_wild_full_pay", "Deuces Wild Full Pay"),
    ]

    private init() {}

    /// Lookup optimal strategy for a hand
    /// Priority: memory cache → binary V2 (full holdEvs) → SQLite → binary V1 (no holdEvs)
    func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult? {
        let key = "\(paytableId):\(hand.canonicalKey)"

        // 1. Check memory cache first
        if let cached = cache[key] {
            return cached
        }

        // 2. Try binary V2 store first (mmap'd with full holdEvs)
        if let v2Result = await BinaryStrategyStoreV2.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: v2Result)
            return v2Result
        }

        // 3. Check SQLite (has full holdEvs data if loaded)
        if let localResult = await LocalStrategyStore.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: localResult)
            return localResult
        }

        // 4. Try binary V1 store (fast but no holdEvs - only bestHold/bestEv)
        if let binaryResult = await BinaryStrategyStore.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            let result = binaryResult.toStrategyResult()
            cacheResult(key: key, result: result)

            // Trigger background load of full data for future lookups
            Task {
                await ensurePaytableLoaded(paytableId: paytableId)
            }

            return result
        }

        // 5. No binary available - try loading from bundle/download
        _ = await ensurePaytableLoaded(paytableId: paytableId)

        // 6. Try SQLite again after loading
        if let localResult = await LocalStrategyStore.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: localResult)
            return localResult
        }

        // No strategy found
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

    /// Check if a paytable has offline data available (binary V2, binary V1, SQLite, bundled, or downloadable)
    func hasOfflineData(paytableId: String) async -> Bool {
        // Check binary V2 store first (has full holdEvs)
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            return true
        }
        // Check binary V1 store (fastest, but no holdEvs)
        if await BinaryStrategyStore.shared.hasStrategyFile(paytableId: paytableId) {
            return true
        }
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
        // Check if binary V2 data is available (ready immediately with full holdEvs)
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            return true  // Binary V2 strategies are always ready
        }

        // Check if binary V1 data is available (ready immediately, no holdEvs)
        if await BinaryStrategyStore.shared.hasStrategyFile(paytableId: paytableId) {
            return true  // Binary V1 strategies are always ready
        }

        // Check if already loaded in SQLite
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

    /// Prepare a paytable with status updates via callback
    /// The callback is called on the main actor for UI updates
    func preparePaytable(paytableId: String, onStatusChange: @escaping @MainActor (PaytableLoadingStatus) -> Void) async -> Bool {
        // Report checking status
        await MainActor.run { onStatusChange(.checking) }

        // Check if binary V2 data is available (ready immediately with full holdEvs)
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            await MainActor.run { onStatusChange(.ready) }
            return true
        }

        // Check if binary V1 data is available (ready immediately)
        if await BinaryStrategyStore.shared.hasStrategyFile(paytableId: paytableId) {
            await MainActor.run { onStatusChange(.ready) }
            return true
        }

        // Check if already loaded in SQLite
        let existingCount = await LocalStrategyStore.shared.getHandCount(paytableId: paytableId)
        if existingCount > 0 {
            await MainActor.run { onStatusChange(.ready) }
            return true
        }

        // Check if this paytable can be loaded
        let isBundled = bundledPaytables[paytableId] != nil
        let isDownloadable = downloadablePaytables[paytableId] != nil

        guard isBundled || isDownloadable else {
            await MainActor.run { onStatusChange(.failed("Strategy not available")) }
            return false
        }

        // Check if another task is already loading
        if let existingTask = loadingTasks[paytableId] {
            await MainActor.run { onStatusChange(isBundled ? .importing : .downloading) }
            let success = await existingTask.value
            await MainActor.run { onStatusChange(success ? .ready : .failed("Loading failed")) }
            return success
        }

        // Create a loading task
        let loadTask = Task<Bool, Never> {
            if isBundled {
                await MainActor.run { onStatusChange(.importing) }
                return await performBundledLoad(paytableId: paytableId)
            } else {
                await MainActor.run { onStatusChange(.downloading) }
                let downloadSuccess = await performDownloadWithProgress(paytableId: paytableId, onStatusChange: onStatusChange)
                return downloadSuccess
            }
        }

        loadingTasks[paytableId] = loadTask
        let success = await loadTask.value
        loadingTasks.removeValue(forKey: paytableId)

        await MainActor.run { onStatusChange(success ? .ready : .failed("Loading failed")) }
        return success
    }

    /// Download with progress updates
    private func performDownloadWithProgress(paytableId: String, onStatusChange: @escaping @MainActor (PaytableLoadingStatus) -> Void) async -> Bool {
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

            // Update status to importing
            await MainActor.run { onStatusChange(.importing) }

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

    /// Check if a paytable needs to be loaded (not in binary V2/V1 or SQLite but is available)
    func paytableNeedsLoading(paytableId: String) async -> Bool {
        // Check if binary V2 data is available (no loading needed, has holdEvs)
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            return false
        }

        // Check if binary V1 data is available (no loading needed)
        if await BinaryStrategyStore.shared.hasStrategyFile(paytableId: paytableId) {
            return false
        }

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
