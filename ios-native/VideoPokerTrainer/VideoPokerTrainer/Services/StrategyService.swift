import Foundation

// MARK: - Download Status

enum StrategyDownloadStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(String)

    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
}

// MARK: - Downloadable Paytable Info

struct DownloadablePaytable: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let family: String
    let fileSize: Int64  // bytes

    var familyEnum: GameFamily? {
        GameFamily(rawValue: family)
    }

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

actor StrategyService {
    static let shared = StrategyService()

    private var cache: [String: StrategyResult] = [:]
    private let maxCacheSize = 100

    // Download tracking
    private var downloadTasks: [String: Task<Bool, Error>] = [:]
    private var downloadProgress: [String: Double] = [:]

    // Manifest cache
    private var manifestCache: [DownloadablePaytable]?
    private var manifestLastFetch: Date?
    private let manifestCacheDuration: TimeInterval = 3600 // 1 hour

    // Supabase storage URL
    private static let storageBaseURL = "https://ctqefgdvqiaiumtmcjdz.supabase.co/storage/v1/object/public/strategies/"
    private static let manifestURL = "https://ctqefgdvqiaiumtmcjdz.supabase.co/storage/v1/object/public/strategies/manifest.json"

    private init() {}

    /// Lookup optimal strategy for a hand using Binary V2 format
    func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult? {
        let key = "\(paytableId):\(hand.canonicalKey)"

        // 1. Check memory cache first
        if let cached = cache[key] {
            return cached
        }

        // 2. Look up from binary V2 store
        if let result = await BinaryStrategyStoreV2.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: result)
            return result
        }

        // No strategy found
        NSLog("⚠️ No strategy found for %@ / %@", paytableId, hand.canonicalKey)
        return nil
    }

    /// Check if a paytable has strategy data available
    func hasOfflineData(paytableId: String) async -> Bool {
        return await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId)
    }

    /// Prepare a paytable for use - preloads the binary file
    /// Returns true if ready, false if not available
    func preparePaytable(paytableId: String) async -> Bool {
        return await BinaryStrategyStoreV2.shared.preload(paytableId: paytableId)
    }

    /// Get all available paytables with bundled strategy data
    func getAvailablePaytables() async -> [String] {
        return await BinaryStrategyStoreV2.shared.getAvailablePaytables()
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

    // MARK: - Manifest & Download Management

    /// Fetch the manifest of all available strategy files from Supabase
    func fetchAvailableStrategies() async throws -> [DownloadablePaytable] {
        // Return cached manifest if still valid
        if let cached = manifestCache,
           let lastFetch = manifestLastFetch,
           Date().timeIntervalSince(lastFetch) < manifestCacheDuration {
            return cached
        }

        guard let url = URL(string: Self.manifestURL) else {
            throw StrategyDownloadError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                NSLog("⚠️ Manifest fetch failed with status: %d", (response as? HTTPURLResponse)?.statusCode ?? 0)
                throw StrategyDownloadError.manifestFetchFailed
            }

            let manifest = try JSONDecoder().decode([DownloadablePaytable].self, from: data)
            manifestCache = manifest
            manifestLastFetch = Date()

            NSLog("✅ Fetched manifest with %d games", manifest.count)
            return manifest
        } catch let error as StrategyDownloadError {
            throw error
        } catch {
            NSLog("⚠️ Manifest fetch error: %@", error.localizedDescription)
            throw StrategyDownloadError.manifestFetchFailed
        }
    }

    /// Get download status for a paytable
    func getDownloadStatus(paytableId: String) async -> StrategyDownloadStatus {
        // Check if already downloaded
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            return .downloaded
        }

        // Check if currently downloading
        if let progress = downloadProgress[paytableId] {
            return .downloading(progress: progress)
        }

        return .notDownloaded
    }

    /// Download a strategy file for a paytable
    func downloadStrategy(paytableId: String, progressHandler: (@Sendable (Double) -> Void)? = nil) async throws -> Bool {
        // Check if already downloaded
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            return true
        }

        // Check if already downloading
        if let existingTask = downloadTasks[paytableId] {
            return try await existingTask.value
        }

        // Start download
        let task = Task<Bool, Error> { [weak self] in
            guard let self = self else { return false }

            let filename = "strategy_\(paytableId.replacingOccurrences(of: "-", with: "_")).vpstrat2"
            let urlString = Self.storageBaseURL + filename

            guard let url = URL(string: urlString) else {
                throw StrategyDownloadError.invalidURL
            }

            NSLog("📥 Starting download: %@", filename)

            // Create download request
            let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw StrategyDownloadError.downloadFailed("Server returned error")
            }

            let expectedLength = httpResponse.expectedContentLength
            var receivedData = Data()
            receivedData.reserveCapacity(Int(expectedLength))

            var bytesReceived: Int64 = 0
            for try await byte in asyncBytes {
                receivedData.append(byte)
                bytesReceived += 1

                if expectedLength > 0 {
                    let progress = Double(bytesReceived) / Double(expectedLength)
                    await self.updateProgress(paytableId: paytableId, progress: progress)
                    progressHandler?(progress)
                }
            }

            // Save to cache directory
            let strategiesDir = await BinaryStrategyStoreV2.shared.getStrategiesDirectory()

            // Create directory if needed
            try FileManager.default.createDirectory(at: strategiesDir, withIntermediateDirectories: true)

            let filePath = strategiesDir.appendingPathComponent(filename)
            try receivedData.write(to: filePath)

            NSLog("✅ Downloaded and saved: %@ (%d bytes)", filename, receivedData.count)

            // Clear progress tracking
            await self.clearDownloadTracking(paytableId: paytableId)

            return true
        }

        downloadTasks[paytableId] = task
        downloadProgress[paytableId] = 0

        do {
            let result = try await task.value
            return result
        } catch {
            downloadTasks.removeValue(forKey: paytableId)
            downloadProgress.removeValue(forKey: paytableId)
            throw error
        }
    }

    /// Cancel a download in progress
    func cancelDownload(paytableId: String) {
        downloadTasks[paytableId]?.cancel()
        downloadTasks.removeValue(forKey: paytableId)
        downloadProgress.removeValue(forKey: paytableId)
    }

    /// Delete a downloaded strategy file
    func deleteStrategy(paytableId: String) async throws {
        let filename = "strategy_\(paytableId.replacingOccurrences(of: "-", with: "_")).vpstrat2"
        let strategiesDir = await BinaryStrategyStoreV2.shared.getStrategiesDirectory()
        let filePath = strategiesDir.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: filePath.path) {
            try FileManager.default.removeItem(at: filePath)
            await BinaryStrategyStoreV2.shared.unload(paytableId: paytableId)
            NSLog("🗑️ Deleted strategy: %@", filename)
        }
    }

    /// Get current download progress for a paytable
    func getDownloadProgress(paytableId: String) -> Double? {
        return downloadProgress[paytableId]
    }

    private func updateProgress(paytableId: String, progress: Double) {
        downloadProgress[paytableId] = progress
    }

    private func clearDownloadTracking(paytableId: String) {
        downloadTasks.removeValue(forKey: paytableId)
        downloadProgress.removeValue(forKey: paytableId)
    }

    /// Clear the manifest cache to force a refresh
    func clearManifestCache() {
        manifestCache = nil
        manifestLastFetch = nil
    }
}

// MARK: - Download Errors

enum StrategyDownloadError: LocalizedError {
    case invalidURL
    case manifestFetchFailed
    case downloadFailed(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .manifestFetchFailed:
            return "Failed to fetch available games list"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .saveFailed(let message):
            return "Failed to save file: \(message)"
        }
    }
}
