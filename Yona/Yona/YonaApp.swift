//
//  YonaApp.swift
//  Yona
//

import SwiftUI
import RevenueCat

@main
struct YonaApp: App {
    @State private var repository: SupabaseRepository
    @State private var auth: AuthStore
    @State private var tiles: TileStore
    @State private var entitlement = EntitlementStore()

    init() {
        // Roomier on-disk image cache so brand logos persist across launches.
        URLCache.shared = URLCache(memoryCapacity: 25_000_000, diskCapacity: 100_000_000)

        // RevenueCat public SDK key. Debug/simulator uses the Test Store (instant fake
        // purchases, no sandbox account needed); Release — TestFlight and the App Store —
        // uses the real App Store key so purchases run through StoreKit (sandbox on TestFlight).
        #if DEBUG
        Purchases.logLevel = .debug
        let revenueCatKey = "test_TrdiFeEWZrOeXGhPPOQMSGmTgFb"
        #else
        let revenueCatKey = "appl_HYjZPwSORjDowXTDRTYDvwRsLaF"
        #endif
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: revenueCatKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )

        let repository = SupabaseRepository()
        _repository = State(initialValue: repository)
        _auth = State(initialValue: AuthStore(repository: repository))
        _tiles = State(initialValue: TileStore(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(repository)
                .environment(auth)
                .environment(tiles)
                .environment(entitlement)
                // Start observing entitlement changes once, on the main actor.
                .task { entitlement.start() }
        }
    }
}
