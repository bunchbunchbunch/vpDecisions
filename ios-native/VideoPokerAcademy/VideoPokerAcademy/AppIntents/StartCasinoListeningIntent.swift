import AppIntents

struct StartCasinoListeningIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Casino Voice Mode"
    static let description = IntentDescription("Start hands-free casino video poker strategy.")

    @MainActor
    func perform() async throws -> some IntentResult {
        // Post a notification that the app can observe to trigger casino mode
        NotificationCenter.default.post(name: .startCasinoListening, object: nil)
        return .result()
    }
}

extension Notification.Name {
    static let startCasinoListening = Notification.Name("startCasinoListening")
}
