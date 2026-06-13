//
//  YonaApp.swift
//  Yona
//

import SwiftUI

@main
struct YonaApp: App {
    @State private var repository: SupabaseRepository
    @State private var auth: AuthStore
    @State private var tiles: TileStore

    init() {
        // Roomier on-disk image cache so brand logos persist across launches.
        URLCache.shared = URLCache(memoryCapacity: 25_000_000, diskCapacity: 100_000_000)

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
        }
    }
}
