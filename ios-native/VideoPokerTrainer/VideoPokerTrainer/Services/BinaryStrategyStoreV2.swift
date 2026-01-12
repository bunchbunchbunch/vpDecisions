import Foundation

/// Memory-mapped binary strategy file reader for VPS2 format
/// Uses .vpstrat2 files for O(log n) lookup with full holdEvs data
///
/// File format:
///   Header (64 bytes):
///     - Magic: "VPS2" (4 bytes)
///     - Version: UInt16 LE (2 bytes) - format version, currently 2
///     - Flags: UInt16 LE (2 bytes) - bit 0: has_joker
///     - Entry count: UInt32 LE (4 bytes)
///     - Key length: UInt8 (1 byte) - 10 for standard, 12 for joker
///     - Reserved: 51 bytes
///   Index section (entry_count * key_length bytes):
///     - Canonical keys in sorted order (ASCII)
///   Data section (entry_count * 66 bytes):
///     - best_hold: UInt8 (1 byte) - bitmask of optimal cards to hold (0-31)
///     - scale: UInt8 (1 byte) - EV scale factor (0-3)
///     - evs[32]: UInt16[32] LE (64 bytes) - EVs for hold masks 0-31
actor BinaryStrategyStoreV2 {
    static let shared = BinaryStrategyStoreV2()

    private static let magic: [UInt8] = [0x56, 0x50, 0x53, 0x32] // "VPS2"
    fileprivate static let headerSize = 64
    private static let dataEntrySize = 66 // 1 (bestHold) + 1 (scale) + 64 (32 * u16)

    /// Scale factors for EV decoding
    private static let scales: [Double] = [0.0001, 0.001, 0.01, 0.1]

    /// Cached memory-mapped files per paytable
    private var mmapCache: [String: MappedStrategyFileV2] = [:]

    private init() {}

    // MARK: - Public API

    /// Look up strategy for a hand using binary search on mmap'd file
    /// Returns full StrategyResult with holdEvs
    func lookup(paytableId: String, handKey: String) -> StrategyResult? {
        guard let mapped = getOrLoadFile(paytableId: paytableId) else {
            return nil
        }

        guard let index = binarySearch(mapped: mapped, handKey: handKey) else {
            return nil
        }

        return readDataEntry(mapped: mapped, index: index)
    }

    /// Check if binary strategy file exists for a paytable
    func hasStrategyFile(paytableId: String) -> Bool {
        return findStrategyFile(paytableId: paytableId) != nil
    }

    /// Get all available binary strategy files (from bundle and cache)
    func getAvailablePaytables() -> [String] {
        var paytableIds = Set<String>()

        // Check bundle resources
        if let bundleURLs = Bundle.main.urls(forResourcesWithExtension: "vpstrat2", subdirectory: nil) {
            for url in bundleURLs {
                let filename = url.deletingPathExtension().lastPathComponent
                if filename.hasPrefix("strategy_") {
                    let id = String(filename.dropFirst("strategy_".count)).replacingOccurrences(of: "_", with: "-")
                    paytableIds.insert(id)
                }
            }
        }

        // Check cache directory
        let strategiesDir = strategiesDirectory()
        if let cacheFiles = try? FileManager.default.contentsOfDirectory(at: strategiesDir, includingPropertiesForKeys: nil) {
            for url in cacheFiles where url.pathExtension == "vpstrat2" {
                let filename = url.deletingPathExtension().lastPathComponent
                if filename.hasPrefix("strategy_") {
                    let id = String(filename.dropFirst("strategy_".count)).replacingOccurrences(of: "_", with: "-")
                    paytableIds.insert(id)
                }
            }
        }

        return Array(paytableIds).sorted()
    }

    /// Preload a strategy file into memory
    func preload(paytableId: String) -> Bool {
        return getOrLoadFile(paytableId: paytableId) != nil
    }

    /// Unload a strategy file from memory
    func unload(paytableId: String) {
        mmapCache.removeValue(forKey: paytableId)
    }

    /// Clear all cached files
    func clearCache() {
        mmapCache.removeAll()
    }

    // MARK: - File Management

    private func strategiesDirectory() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent("binary_strategies_v2", isDirectory: true)
    }

    private func strategyFilename(paytableId: String) -> String {
        return "strategy_\(paytableId.replacingOccurrences(of: "-", with: "_"))"
    }

    /// Find strategy file - checks bundle first, then cache directory
    private func findStrategyFile(paytableId: String) -> URL? {
        let filename = strategyFilename(paytableId: paytableId)

        // Check app bundle first (bundled strategies)
        if let bundlePath = Bundle.main.url(forResource: filename, withExtension: "vpstrat2") {
            return bundlePath
        }

        // Check cache directory (downloaded strategies)
        let cachePath = strategiesDirectory().appendingPathComponent("\(filename).vpstrat2")
        if FileManager.default.fileExists(atPath: cachePath.path) {
            return cachePath
        }

        return nil
    }

    private func getOrLoadFile(paytableId: String) -> MappedStrategyFileV2? {
        if let cached = mmapCache[paytableId] {
            return cached
        }

        guard let path = findStrategyFile(paytableId: paytableId) else {
            return nil
        }

        guard let mapped = MappedStrategyFileV2(url: path) else {
            return nil
        }

        mmapCache[paytableId] = mapped
        return mapped
    }

    // MARK: - Binary Search

    private func binarySearch(mapped: MappedStrategyFileV2, handKey: String) -> Int? {
        let keyLength = Int(mapped.keyLength)
        let keyBytes = Array(handKey.utf8)

        guard keyBytes.count == keyLength else {
            NSLog("BinaryStrategyStoreV2: Key length mismatch - expected \(keyLength), got \(keyBytes.count)")
            return nil
        }

        var low = 0
        var high = mapped.entryCount - 1

        while low <= high {
            let mid = (low + high) / 2
            let indexOffset = Self.headerSize + mid * keyLength

            // Compare key at mid position
            let cmp = mapped.data.withUnsafeBytes { ptr -> Int in
                let keyPtr = ptr.baseAddress!.advanced(by: indexOffset)
                for i in 0..<keyLength {
                    let a = keyPtr.load(fromByteOffset: i, as: UInt8.self)
                    let b = keyBytes[i]
                    if a < b { return -1 }
                    if a > b { return 1 }
                }
                return 0
            }

            if cmp == 0 {
                return mid
            } else if cmp < 0 {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return nil
    }

    // MARK: - Data Reading

    private func readDataEntry(mapped: MappedStrategyFileV2, index: Int) -> StrategyResult {
        let indexSize = mapped.entryCount * Int(mapped.keyLength)
        let dataStart = Self.headerSize + indexSize
        let entryOffset = dataStart + index * Self.dataEntrySize

        return mapped.data.withUnsafeBytes { ptr -> StrategyResult in
            let entryPtr = ptr.baseAddress!.advanced(by: entryOffset)

            // Read bestHold (1 byte)
            let bestHold = Int(entryPtr.load(as: UInt8.self))

            // Read scale (1 byte)
            let scale = Int(entryPtr.load(fromByteOffset: 1, as: UInt8.self))
            let scaleFactor = Self.scales[min(scale, 3)]

            // Read 32 EVs as u16 LE
            var holdEvs: [String: Double] = [:]
            var bestEv: Double = 0

            for i in 0..<32 {
                let evOffset = 2 + i * 2
                let evLo = entryPtr.load(fromByteOffset: evOffset, as: UInt8.self)
                let evHi = entryPtr.load(fromByteOffset: evOffset + 1, as: UInt8.self)
                let evRaw = UInt16(evLo) | (UInt16(evHi) << 8)
                let ev = Double(evRaw) * scaleFactor

                holdEvs[String(i)] = ev

                if i == bestHold {
                    bestEv = ev
                }
            }

            return StrategyResult(bestHold: bestHold, bestEv: bestEv, holdEvs: holdEvs)
        }
    }
}

// MARK: - Memory Mapped File

private final class MappedStrategyFileV2 {
    let data: Data
    let entryCount: Int
    let keyLength: UInt8
    let hasJoker: Bool

    init?(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("BinaryStrategyStoreV2: File not found: \(url.path)")
            return nil
        }

        // Memory-map the file
        guard let mappedData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            NSLog("BinaryStrategyStoreV2: Failed to mmap file: \(url.path)")
            return nil
        }

        guard mappedData.count >= BinaryStrategyStoreV2.headerSize else {
            NSLog("BinaryStrategyStoreV2: File too small: \(mappedData.count) bytes")
            return nil
        }

        // Validate header - "VPS2"
        let valid = mappedData.withUnsafeBytes { ptr -> Bool in
            let magic = ptr.baseAddress!
            return magic.load(as: UInt8.self) == 0x56 &&         // V
                   magic.load(fromByteOffset: 1, as: UInt8.self) == 0x50 && // P
                   magic.load(fromByteOffset: 2, as: UInt8.self) == 0x53 && // S
                   magic.load(fromByteOffset: 3, as: UInt8.self) == 0x32    // 2
        }

        guard valid else {
            NSLog("BinaryStrategyStoreV2: Invalid magic number")
            return nil
        }

        // Read header fields
        let (count, keyLen, joker) = mappedData.withUnsafeBytes { ptr -> (Int, UInt8, Bool) in
            let base = ptr.baseAddress!
            let flags = UInt16(base.load(fromByteOffset: 6, as: UInt8.self)) |
                       (UInt16(base.load(fromByteOffset: 7, as: UInt8.self)) << 8)
            let entryCount = UInt32(base.load(fromByteOffset: 8, as: UInt8.self)) |
                            (UInt32(base.load(fromByteOffset: 9, as: UInt8.self)) << 8) |
                            (UInt32(base.load(fromByteOffset: 10, as: UInt8.self)) << 16) |
                            (UInt32(base.load(fromByteOffset: 11, as: UInt8.self)) << 24)
            let keyLength = base.load(fromByteOffset: 12, as: UInt8.self)
            return (Int(entryCount), keyLength, (flags & 1) != 0)
        }

        self.data = mappedData
        self.entryCount = count
        self.keyLength = keyLen
        self.hasJoker = joker

        NSLog("BinaryStrategyStoreV2: Loaded \(url.lastPathComponent) - \(entryCount) entries, key length \(keyLength)")
    }
}
