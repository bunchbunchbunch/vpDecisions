import Foundation
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    private static let supabaseURL = URL(string: "https://ctqefgdvqiaiumtmcjdz.supabase.co")!
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0cWVmZ2R2cWlhaXVtdG1jamR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwMTExMzksImV4cCI6MjA4MTU4NzEzOX0.SSrvFVyedTsjq2r9mWMj8SKV4bZfRtp0MESavfz3AiI"

    let client: SupabaseClient

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        client = SupabaseClient(
            supabaseURL: Self.supabaseURL,
            supabaseKey: Self.supabaseAnonKey
        )

        // Listen for auth state changes
        Task {
            for await state in client.auth.authStateChanges {
                await MainActor.run {
                    self.currentUser = state.session?.user
                    self.isAuthenticated = state.session != nil
                }
            }
        }
    }

    // MARK: - Authentication

    func signInWithEmail(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUpWithEmail(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func getCurrentSession() async -> Session? {
        try? await client.auth.session
    }

    // MARK: - Profile Management

    func upsertProfile(user: User) async throws {
        let profile: [String: AnyJSON] = [
            "id": .string(user.id.uuidString),
            "email": .string(user.email ?? ""),
            "full_name": .string(user.userMetadata["full_name"]?.stringValue ?? ""),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]

        try await client
            .from("profiles")
            .upsert(profile, onConflict: "id")
            .execute()
    }

    // MARK: - Strategy Lookups

    func lookupStrategy(paytableId: String, handKey: String) async throws -> StrategyResult? {
        let response: [StrategyResult] = try await client
            .from("strategy")
            .select("best_hold, best_ev, hold_evs")
            .eq("paytable_id", value: paytableId)
            .eq("hand_key", value: handKey)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Hand Attempts

    func saveHandAttempt(_ attempt: HandAttempt) async throws {
        try await client
            .from("hand_attempts")
            .insert(attempt)
            .execute()
    }

    // MARK: - Mastery Scores

    func getMasteryScores(userId: UUID, paytableId: String) async throws -> [MasteryScore] {
        try await client
            .from("mastery_scores")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("paytable_id", value: paytableId)
            .execute()
            .value
    }

    func upsertMasteryScore(_ score: MasteryScore) async throws {
        try await client
            .from("mastery_scores")
            .upsert(score, onConflict: "user_id,paytable_id,category")
            .execute()
    }

    // MARK: - Test Connection

    func testConnection() async throws -> Bool {
        let result: [StrategyResult] = try await client
            .from("strategy")
            .select("best_hold, best_ev, hold_evs")
            .limit(1)
            .execute()
            .value

        return !result.isEmpty
    }
}
