//
//  TileCache.swift
//  Yona
//
//  Tiny on-disk cache of the tile list, keyed per user, so the Home grid can
//  render instantly on cold launch before the network refresh lands. Lives in
//  the caches directory (the system may purge it — that's fine, it's a cache).
//

import Foundation

struct TileCache {
    private let directory: URL

    init() {
        directory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private func fileURL(userID: String) -> URL {
        directory.appendingPathComponent("tiles-\(userID).json")
    }

    func load(userID: String) -> [Tile]? {
        guard let data = try? Data(contentsOf: fileURL(userID: userID)) else { return nil }
        return try? JSONDecoder().decode([Tile].self, from: data)
    }

    func save(_ tiles: [Tile], userID: String) {
        guard let data = try? JSONEncoder().encode(tiles) else { return }
        try? data.write(to: fileURL(userID: userID), options: .atomic)
    }
}
