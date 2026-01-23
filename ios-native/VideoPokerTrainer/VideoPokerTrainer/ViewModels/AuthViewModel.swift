import Foundation
import Supabase
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    init() {
        // Check for existing session on init
        Task {
            await checkSession()
        }

        // Listen for auth state changes
        Task {
            for await state in supabase.client.auth.authStateChanges {
                self.currentUser = state.session?.user
                self.isAuthenticated = state.session != nil

                // Upsert profile on sign in
                if let user = state.session?.user {
                    try? await supabase.upsertProfile(user: user)
                }
            }
        }
    }

    func checkSession() async {
        isLoading = true
        if let session = await supabase.getCurrentSession() {
            currentUser = session.user
            isAuthenticated = true
        }
        isLoading = false
    }

    func signInWithEmail(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signInWithEmail(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUpWithEmail(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signUpWithEmail(email: email, password: password)
            errorMessage = "Account created! You can now sign in."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.resetPasswordForEmail(email: email)
            errorMessage = "Password reset email sent! Check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updatePassword(newPassword: String) async {
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password"
            return
        }

        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.updatePassword(newPassword: newPassword)
            errorMessage = "Password updated successfully!"
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateProfile(fullName: String) async {
        guard let userId = currentUser?.id else {
            errorMessage = "No user logged in"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.updateProfile(userId: userId, fullName: fullName)
            // Refresh the current user to get updated metadata
            await checkSession()
            errorMessage = "Profile updated successfully"
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signInWithMagicLink(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signInWithMagicLink(email: email)
            errorMessage = "Magic link sent! Check your email to sign in."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let url = try await supabase.signInWithGoogle()
            await UIApplication.shared.open(url)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Quick login for testing
    func quickLogin() async {
        await signInWithEmail(
            email: "bhsapcsturnin@gmail.com",
            password: "test1234"
        )
    }
}
