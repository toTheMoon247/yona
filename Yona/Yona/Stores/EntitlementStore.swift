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

    /// Grants Premium without a real purchase — the mock unlock used in Debug and
    /// TestFlight (see `AppBuild.usesMockPurchases`). Real purchases (RevenueCat)
    /// replace this in App Store production builds.
    func setDevPremium(_ value: Bool) {
        isPremium = value
    }
}

/// Which build we're running in, for gating the mock paywall.
enum AppBuild {
    /// True where the paywall should mock-unlock instead of charging: Debug (Xcode)
    /// and TestFlight (its receipt is named `sandboxReceipt`). False in App Store
    /// production, so the real purchase path runs there.
    static var usesMockPurchases: Bool {
        #if DEBUG
        return true
        #else
        // TestFlight's receipt is named "sandboxReceipt" (App Store's is "receipt").
        // Read via KVC to sidestep the iOS 18 deprecation of `appStoreReceiptURL` —
        // this is a temporary mock gate, removed when RevenueCat lands.
        let receiptURL = Bundle.main.value(forKey: "appStoreReceiptURL") as? URL
        return receiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
}
