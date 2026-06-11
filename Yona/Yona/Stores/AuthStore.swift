//
//  AuthStore.swift
//  Yona
//
//  Owns auth/session state for the UI. Skeleton for Phase 0; Google sign-in,
//  session restore, and sign-out are implemented in Phase 1.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthStore {
    enum SessionState: Equatable {
        case unknown      // launch, before we've checked for a stored session
        case signedOut
        case signedIn
    }

    private(set) var sessionState: SessionState = .unknown

    private let repository: SupabaseRepository

    init(repository: SupabaseRepository) {
        self.repository = repository
    }

    // Phase 1:
    //   func restoreSession() async
    //   func signInWithGoogle() async
    //   func signOut() async
}
