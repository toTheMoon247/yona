//
//  SupabaseRepository.swift
//  Yona
//
//  The single seam between the app and Supabase. Stores call into here; nothing
//  else touches the SDK directly.
//

import Foundation
import Supabase

final class SupabaseRepository {
    let client: SupabaseClient

    /// Mirrors `AppConfig.isConfigured` — false until real credentials are present.
    let isConfigured: Bool

    init(config: AppConfig = .shared) {
        self.isConfigured = config.isConfigured
        self.client = SupabaseClient(
            supabaseURL: config.supabaseURL,
            supabaseKey: config.supabaseAnonKey
        )
    }

    // MARK: - Tiles

    /// Fetch the signed-in user's tiles, newest first. RLS scopes this to the caller.
    func fetchTiles() async throws -> [Tile] {
        try await client
            .from("tiles")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Insert a tile (user_id is filled by the column's `auth.uid()` default) and
    /// return the created row.
    func createTile(title: String, url: String, notes: String?) async throws -> Tile {
        struct Payload: Encodable {
            let title: String
            let url: String
            let notes: String?
        }
        return try await client
            .from("tiles")
            .insert(Payload(title: title, url: url, notes: notes))
            .select()
            .single()
            .execute()
            .value
    }
}
