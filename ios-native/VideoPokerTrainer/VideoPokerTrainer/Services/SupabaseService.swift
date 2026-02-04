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
            supabaseKey: Self.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
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

    func deleteAccount() async throws {
        try await client.rpc("delete_user_account").execute()
    }

    func getCurrentSession() async -> Session? {
        try? await client.auth.session
    }

    func resetPasswordForEmail(email: String) async throws {
        // Supabase will send email with deep link to vptrainer://reset-password
        let redirectTo = URL(string: "vptrainer://reset-password")!
        try await client.auth.resetPasswordForEmail(email, redirectTo: redirectTo)
    }

    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    func signInWithMagicLink(email: String) async throws {
        // Supabase will send email with deep link to vptrainer://magic-link
        let redirectTo = URL(string: "vptrainer://magic-link")!
        try await client.auth.signInWithOTP(email: email, redirectTo: redirectTo)
    }

    func signInWithGoogle() throws -> URL {
        let redirectTo = URL(string: "vptrainer://google-callback")!
        return try client.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: redirectTo
        )
    }

    func signInWithApple(idToken: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken)
        )
    }

    func handleOAuthCallback(url: URL) async throws {
        try await client.auth.session(from: url)
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

    func updateProfile(userId: UUID, fullName: String) async throws {
        // Update auth user metadata so it's available in currentUser.userMetadata
        try await client.auth.update(user: UserAttributes(data: ["full_name": .string(fullName)]))

        // Also update the profiles table for consistency
        let profile: [String: AnyJSON] = [
            "full_name": .string(fullName),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]

        try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Strategy Lookups

    func lookupStrategy(paytableId: String, handKey: String) async throws -> StrategyResult? {
        NSLog("🔎 Supabase query: paytable_id=%@, hand_key=%@", paytableId, handKey)
        let response: [StrategyResult] = try await client
            .from("strategy")
            .select("best_hold, best_ev, hold_evs")
            .eq("paytable_id", value: paytableId)
            .eq("hand_key", value: handKey)
            .limit(1)
            .execute()
            .value

        if let result = response.first {
            NSLog("✅ Found strategy: best_ev=%.4f", result.bestEv)
        } else {
            NSLog("❌ No strategy found for %@ / %@", paytableId, handKey)
        }
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
