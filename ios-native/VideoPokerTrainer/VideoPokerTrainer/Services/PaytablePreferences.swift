import Foundation

/// Storage mode for paytable strategy data
enum PaytableStorageMode: String, Codable {
    case ready = "ready"           // Persisted in SQLite, instant after first use
    case compressed = "compressed" // Cleared on app launch, re-decompresses each session
}

/// Manages user preferences for paytable storage
class PaytablePreferences {
    static let shared = PaytablePreferences()

    private let defaults = UserDefaults.standard
    private let preferencesKey = "paytableStorageModes"
    private let defaultModeKey = "defaultPaytableStorageMode"

    private init() {}

    // MARK: - Per-Paytable Preferences

    /// Get the storage mode for a specific paytable
    func getStorageMode(for paytableId: String) -> PaytableStorageMode {
        let prefs = getAllPreferences()
        return prefs[paytableId] ?? .ready  // Default to ready
    }

    /// Set the storage mode for a specific paytable
    func setStorageMode(_ mode: PaytableStorageMode, for paytableId: String) {
        var prefs = getAllPreferences()
        prefs[paytableId] = mode
        savePreferences(prefs)
        NSLog("📦 Set storage mode for %@: %@", paytableId, mode.rawValue)
    }

    /// Get all paytable preferences
    func getAllPreferences() -> [String: PaytableStorageMode] {
        guard let data = defaults.data(forKey: preferencesKey),
              let decoded = try? JSONDecoder().decode([String: PaytableStorageMode].self, from: data) else {
            return [:]
        }
        return decoded
    }

    /// Check if a paytable should be cleared on app launch
    func shouldClearOnLaunch(paytableId: String) -> Bool {
        return getStorageMode(for: paytableId) == .compressed
    }

    /// Get list of paytable IDs that should be kept (not cleared on launch)
    func getReadyPaytableIds() -> [String] {
        return getAllPreferences()
            .filter { $0.value == .ready }
            .map { $0.key }
    }

    /// Get list of paytable IDs that should be cleared on launch
    func getCompressedPaytableIds() -> [String] {
        return getAllPreferences()
            .filter { $0.value == .compressed }
            .map { $0.key }
    }

    // MARK: - Default Preference for New Downloads

    /// Get the default storage mode for newly downloaded paytables
    var defaultStorageMode: PaytableStorageMode {
        get {
            guard let rawValue = defaults.string(forKey: defaultModeKey),
                  let mode = PaytableStorageMode(rawValue: rawValue) else {
                return .ready  // Default: new downloads are "Ready"
            }
            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: defaultModeKey)
            NSLog("📦 Set default storage mode: %@", newValue.rawValue)
        }
    }

    // MARK: - Private Helpers

    private func savePreferences(_ prefs: [String: PaytableStorageMode]) {
        if let data = try? JSONEncoder().encode(prefs) {
            defaults.set(data, forKey: preferencesKey)
        }
    }

    /// Remove preference for a paytable (used when deleting)
    func removePreference(for paytableId: String) {
        var prefs = getAllPreferences()
        prefs.removeValue(forKey: paytableId)
        savePreferences(prefs)
    }

    /// Reset all preferences to defaults
    func resetAllPreferences() {
        defaults.removeObject(forKey: preferencesKey)
        defaults.removeObject(forKey: defaultModeKey)
        NSLog("📦 Reset all paytable preferences")
    }
}
