//
//  AuthStore.swift
//  Yona
//
//  Owns auth/session state for the UI. Google sign-in runs through Supabase's
//  ASWebAuthenticationSession flow; Apple sign-in is a stub until the Apple
//  Developer Program is enrolled (Phase 5).
//

import Foundation
import Observation
import Supabase
import AuthenticationServices

@MainActor
@Observable
final class AuthStore {
    enum SessionState: Equatable {
        case unknown      // launch, before we've checked for a stored session
        case signedOut
        case signedIn
    }

    private(set) var sessionState: SessionState = .unknown
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?

    private let client: SupabaseClient
    private let redirectURL = URL(string: "yona://auth-callback")!
    private var observing = false

    init(repository: SupabaseRepository) {
        self.client = repository.client
    }

    /// Hydrate initial state, then listen for auth changes. Call once at launch.
    func observeAuthChanges() async {
        guard !observing else { return }
        observing = true

        // Immediate initial state from any stored/refreshable session.
        do {
            _ = try await client.auth.session
            sessionState = .signedIn
        } catch {
            sessionState = .signedOut
        }

        // Long-lived stream of subsequent changes.
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .signedIn, .tokenRefreshed, .userUpdated, .initialSession:
                sessionState = session != nil ? .signedIn : .signedOut
            case .signedOut:
                sessionState = .signedOut
            default:
                break
            }
        }
    }

    func signInWithGoogle() async {
        isAuthenticating = true
        errorMessage = nil
        defer { isAuthenticating = false }

        do {
            _ = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL,
                scopes: "email profile"
            )
            // `authStateChanges` flips `sessionState` to .signedIn.
        } catch {
            if isUserCancellation(error) { return }
            errorMessage = "Sign-in failed. Please try again."
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = "Sign-out failed. Please try again."
        }
    }

    /// True when the user simply dismissed the web sign-in sheet — not a real error.
    private func isUserCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let asError = error as? ASWebAuthenticationSessionError,
           asError.code == .canceledLogin {
            return true
        }
        return false
    }
}
