//
//  YonaApp.swift
//  Yona
//

import SwiftUI

@main
struct YonaApp: App {
    @State private var auth: AuthStore
    @State private var tiles: TileStore

    init() {
        let repository = SupabaseRepository()
        _auth = State(initialValue: AuthStore(repository: repository))
        _tiles = State(initialValue: TileStore(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .environment(tiles)
        }
    }
}
