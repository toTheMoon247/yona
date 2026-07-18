//
//  EntitlementStore.swift
//  Yona
//
//  Owns the user's Premium entitlement, the free-tier limit, and the purchase flow.
//  RevenueCat is the source of truth: `isPremium` is driven by the "Yona Pro"
//  entitlement, updated live via `customerInfoStream`. A DEBUG-only dev toggle can
//  still flip Premium locally without a real purchase (see `setDevPremium`).
//

import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class EntitlementStore {
    /// RevenueCat entitlement identifier that grants Premium (from the RevenueCat dashboard).
    static let premiumEntitlementID = "Yona Pro"

    /// Whether the user has Premium (unlimited tiles). Driven by RevenueCat.
    private(set) var isPremium = false

    /// Free users keep up to this many tiles; adding beyond requires Premium.
    let freeTileLimit = 4

    /// The package sold on the paywall, from the current Offering (nil until loaded).
    private(set) var unlockPackage: Package?

    /// True while a purchase or restore is in flight (drives the paywall's button spinner).
    private(set) var isPurchasing = false

    /// A user-facing purchase/restore error to surface on the paywall, or nil.
    var purchaseError: String?

    #if DEBUG
    /// Debug-only override so the dev menu can flip Premium without a real purchase.
    private var devPremiumOverride = false
    #endif

    /// Localized price string from the store (e.g. "$5.99"), or nil until the offering loads.
    var priceText: String? {
        unlockPackage?.storeProduct.localizedPriceString
    }

    /// Existing tiles always stay — this only gates *adding* a new tile past the limit.
    func canAddTile(currentCount: Int) -> Bool {
        isPremium || currentCount < freeTileLimit
    }

    // MARK: - Lifecycle

    /// Begins observing RevenueCat for entitlement changes and loads the offering.
    /// Call once at launch, after `Purchases.configure`.
    func start() {
        Task { await refreshCustomerInfo() }
        Task { await loadOffering() }
        Task {
            // Real-time updates: renewals, restores, purchases made on other devices.
            for await info in Purchases.shared.customerInfoStream {
                apply(info)
            }
        }
    }

    /// Fetches the latest customer info once (also primes from RevenueCat's cache).
    func refreshCustomerInfo() async {
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            // Non-fatal: keep the current value; the stream will correct us later.
            print("[Entitlement] customerInfo failed: \(error.localizedDescription)")
        }
    }

    /// Loads the current Offering's package to display and purchase on the paywall.
    func loadOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            // Single-product app: use the current offering's first available package
            // (the "Lifetime" one-time unlock).
            unlockPackage = offerings.current?.availablePackages.first
        } catch {
            print("[Entitlement] offerings failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase / Restore

    /// Buys the unlock package. Returns true once the entitlement is active.
    @discardableResult
    func purchase() async -> Bool {
        guard let package = unlockPackage else {
            // Offering hasn't loaded yet — try once more, then bail if still missing.
            await loadOffering()
            guard unlockPackage != nil else {
                purchaseError = "Products are still loading. Please try again in a moment."
                return false
            }
            return await purchase()
        }

        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return false }
            apply(result.customerInfo)
            return isEntitled(result.customerInfo)
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    /// Restores previous purchases. Returns true if the entitlement is now active.
    @discardableResult
    func restore() async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            let entitled = isEntitled(info)
            if !entitled {
                purchaseError = "No previous purchase was found to restore."
            }
            return entitled
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Entitlement state

    private func apply(_ info: CustomerInfo) {
        let entitled = isEntitled(info)
        #if DEBUG
        isPremium = entitled || devPremiumOverride
        #else
        isPremium = entitled
        #endif
    }

    private func isEntitled(_ info: CustomerInfo) -> Bool {
        info.entitlements.all[Self.premiumEntitlementID]?.isActive == true
    }

    #if DEBUG
    /// Debug-only: flip Premium without a real purchase (used by the Home dev menu).
    func setDevPremium(_ value: Bool) {
        devPremiumOverride = value
        isPremium = value
    }
    #endif
}
