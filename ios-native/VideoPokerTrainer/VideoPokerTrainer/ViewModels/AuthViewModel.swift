import AuthenticationServices
import Foundation
import Sentry
import Supabase
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Supabase.User?
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

                // Update Sentry user context
                if let user = state.session?.user {
                    let sentryUser = Sentry.User(userId: user.id.uuidString)
                    sentryUser.email = user.email
                    SentrySDK.setUser(sentryUser)
                    try? await supabase.upsertProfile(user: user)
                } else {
                    SentrySDK.setUser(nil)
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

    func deleteAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.deleteAccount()
            await PendingAttemptsStore.shared.clearAllAttempts()
            try? await supabase.signOut()
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

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            let credential = try await performAppleSignIn()

            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Failed to get identity token from Apple"
                isLoading = false
                return
            }

            try await supabase.signInWithApple(idToken: idToken)

            // Save full name if available (only provided on first sign-in)
            if let fullName = credential.fullName {
                let name = PersonNameComponentsFormatter.localizedString(from: fullName, style: .default)
                if !name.isEmpty {
                    _ = try? await supabase.client.auth.update(
                        user: UserAttributes(data: ["full_name": .string(name)])
                    )
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func performAppleSignIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate(continuation: continuation)
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = delegate
            controller.presentationContextProvider = delegate

            // Retain the delegate until the flow completes
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

            controller.performRequests()
        }
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

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>
    private var hasResumed = false

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard !hasResumed else { return }
        hasResumed = true
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation.resume(returning: credential)
        } else {
            continuation.resume(throwing: AuthError.appleSignInFailed("Unexpected credential type"))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(throwing: error)
    }
}

private enum AuthError: LocalizedError {
    case appleSignInFailed(String)

    var errorDescription: String? {
        switch self {
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        }
    }
}
