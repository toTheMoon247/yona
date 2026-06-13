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

    /// Update a tile and return the refreshed row (`updated_at` is bumped by a DB trigger).
    func updateTile(id: UUID, title: String, url: String, notes: String?) async throws -> Tile {
        // Custom encoder so a nil `notes` is sent as an explicit `null` (clearing the
        // column) instead of being omitted — synthesized Encodable drops nil optionals,
        // which would leave the old note in place.
        struct Payload: Encodable {
            let title: String
            let url: String
            let notes: String?
            enum CodingKeys: String, CodingKey { case title, url, notes }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(title, forKey: .title)
                try container.encode(url, forKey: .url)
                try container.encode(notes, forKey: .notes) // writes null when nil
            }
        }
        return try await client
            .from("tiles")
            .update(Payload(title: title, url: url, notes: notes))
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteTile(id: UUID) async throws {
        try await client
            .from("tiles")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
