import Foundation

/// Memory-mapped binary strategy file reader
/// Uses .vpstrat files for O(log n) lookup with no decompression overhead
///
/// File format:
///   Header (64 bytes):
///     - Magic: "VPST" (4 bytes)
///     - Version: UInt16 LE (2 bytes)
///     - Flags: UInt16 LE (2 bytes) - bit 0: has_joker
///     - Entry count: UInt32 LE (4 bytes)
///     - Key length: UInt8 (1 byte)
///     - Reserved: 51 bytes
///   Index section (entry_count * key_length bytes):
///     - Canonical keys in sorted order (ASCII)
///   Data section (entry_count * 5 bytes):
///     - hold_mask: UInt8 (1 byte)
///     - ev: Float32 LE (4 bytes)
actor BinaryStrategyStore {
    static let shared = BinaryStrategyStore()

    private static let magic: [UInt8] = [0x56, 0x50, 0x53, 0x54] // "VPST"
    fileprivate static let headerSize = 64
    private static let dataEntrySize = 5

    /// Cached memory-mapped files per paytable
    private var mmapCache: [String: MappedStrategyFile] = [:]

    private init() {}

    // MARK: - Public API

    /// Look up strategy for a hand using binary search on mmap'd file
    /// Returns nil if file not found or hand not in index
    func lookup(paytableId: String, handKey: String) -> BinaryStrategyResult? {
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
        if let bundleURLs = Bundle.main.urls(forResourcesWithExtension: "vpstrat", subdirectory: nil) {
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
            for url in cacheFiles where url.pathExtension == "vpstrat" {
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
        return caches.appendingPathComponent("binary_strategies", isDirectory: true)
    }

    private func strategyFilename(paytableId: String) -> String {
        return "strategy_\(paytableId.replacingOccurrences(of: "-", with: "_"))"
    }

    /// Find strategy file - checks bundle first, then cache directory
    private func findStrategyFile(paytableId: String) -> URL? {
        let filename = strategyFilename(paytableId: paytableId)

        // Check app bundle first (bundled strategies)
        if let bundlePath = Bundle.main.url(forResource: filename, withExtension: "vpstrat") {
            return bundlePath
        }

        // Check cache directory (downloaded strategies)
        let cachePath = strategiesDirectory().appendingPathComponent("\(filename).vpstrat")
        if FileManager.default.fileExists(atPath: cachePath.path) {
            return cachePath
        }

        return nil
    }

    private func getOrLoadFile(paytableId: String) -> MappedStrategyFile? {
        if let cached = mmapCache[paytableId] {
            return cached
        }

        guard let path = findStrategyFile(paytableId: paytableId) else {
            return nil
        }

        guard let mapped = MappedStrategyFile(url: path) else {
            return nil
        }

        mmapCache[paytableId] = mapped
        return mapped
    }

    // MARK: - Binary Search

    private func binarySearch(mapped: MappedStrategyFile, handKey: String) -> Int? {
        let keyLength = Int(mapped.keyLength)
        let keyBytes = Array(handKey.utf8)

        guard keyBytes.count == keyLength else {
            NSLog("BinaryStrategyStore: Key length mismatch - expected \(keyLength), got \(keyBytes.count)")
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

    private func readDataEntry(mapped: MappedStrategyFile, index: Int) -> BinaryStrategyResult {
        let indexSize = mapped.entryCount * Int(mapped.keyLength)
        let dataStart = Self.headerSize + indexSize
        let entryOffset = dataStart + index * Self.dataEntrySize

        return mapped.data.withUnsafeBytes { ptr -> BinaryStrategyResult in
            let entryPtr = ptr.baseAddress!.advanced(by: entryOffset)

            let holdMask = entryPtr.load(as: UInt8.self)

            // Read Float32 LE
            let evBytes = (
                entryPtr.load(fromByteOffset: 1, as: UInt8.self),
                entryPtr.load(fromByteOffset: 2, as: UInt8.self),
                entryPtr.load(fromByteOffset: 3, as: UInt8.self),
                entryPtr.load(fromByteOffset: 4, as: UInt8.self)
            )
            let evBits = UInt32(evBytes.0) | (UInt32(evBytes.1) << 8) | (UInt32(evBytes.2) << 16) | (UInt32(evBytes.3) << 24)
            let ev = Float(bitPattern: evBits)

            return BinaryStrategyResult(bestHold: Int(holdMask), bestEv: Double(ev))
        }
    }
}

// MARK: - Memory Mapped File

private final class MappedStrategyFile {
    let data: Data
    let entryCount: Int
    let keyLength: UInt8
    let hasJoker: Bool

    init?(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("BinaryStrategyStore: File not found: \(url.path)")
            return nil
        }

        // Memory-map the file
        guard let mappedData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            NSLog("BinaryStrategyStore: Failed to mmap file: \(url.path)")
            return nil
        }

        guard mappedData.count >= BinaryStrategyStore.headerSize else {
            NSLog("BinaryStrategyStore: File too small: \(mappedData.count) bytes")
            return nil
        }

        // Validate header
        let valid = mappedData.withUnsafeBytes { ptr -> Bool in
            let magic = ptr.baseAddress!
            return magic.load(as: UInt8.self) == 0x56 &&
                   magic.load(fromByteOffset: 1, as: UInt8.self) == 0x50 &&
                   magic.load(fromByteOffset: 2, as: UInt8.self) == 0x53 &&
                   magic.load(fromByteOffset: 3, as: UInt8.self) == 0x54
        }

        guard valid else {
            NSLog("BinaryStrategyStore: Invalid magic number")
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

        NSLog("BinaryStrategyStore: Loaded \(url.lastPathComponent) - \(entryCount) entries, key length \(keyLength)")
    }
}

// MARK: - Result Type

/// Simplified strategy result for binary format (no holdEvs)
struct BinaryStrategyResult {
    let bestHold: Int
    let bestEv: Double

    /// Convert to full StrategyResult with empty holdEvs
    func toStrategyResult() -> StrategyResult {
        return StrategyResult(bestHold: bestHold, bestEv: bestEv, holdEvs: [:])
    }
}
