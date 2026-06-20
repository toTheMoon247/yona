//
//  EntitlementStore.swift
//  Yona
//
//  Owns the user's Premium entitlement and the free-tier limit. Until RevenueCat
//  is wired up, `isPremium` is an in-memory flag (a DEBUG dev-unlock flips it) so
//  the gate + paywall can be built and tested. Later, RevenueCat drives `isPremium`.
//

import Foundation
import Observation

@MainActor
@Observable
final class EntitlementStore {
    /// Whether the user has Premium (unlimited tiles).
    private(set) var isPremium = false

    /// Free users keep up to this many tiles; adding beyond requires Premium.
    let freeTileLimit = 4

    /// Existing tiles always stay — this only gates *adding* a new tile past the limit.
    func canAddTile(currentCount: Int) -> Bool {
        isPremium || currentCount < freeTileLimit
    }

    #if DEBUG
    /// Dev-only: simulate a purchase until RevenueCat is connected.
    func setDevPremium(_ value: Bool) {
        isPremium = value
    }
    #endif
}
