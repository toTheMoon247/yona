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

    /// The signed-in user's id (for per-user caching), or nil when signed out.
    var currentUserID: String? {
        client.auth.currentUser?.id.uuidString
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
    func createTile(_ draft: TileDraft) async throws -> Tile {
        try await client
            .from("tiles")
            .insert(TilePayload(draft))
            .select()
            .single()
            .execute()
            .value
    }

    /// Update a tile and return the refreshed row (`updated_at` is bumped by a DB trigger).
    func updateTile(id: UUID, _ draft: TileDraft) async throws -> Tile {
        try await client
            .from("tiles")
            .update(TilePayload(draft))
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

/// Encodable body for tile insert/update. Nil fields are written as explicit
/// `null` (so clearing a value on edit persists) — synthesized Encodable would
/// omit them, leaving the old value in place.
private struct TilePayload: Encodable {
    let title: String
    let url: String
    let notes: String?
    let costAmount: Double?
    let costPeriod: String?
    let renewalDate: String?
    let renewalRepeat: String?

    enum CodingKeys: String, CodingKey {
        case title, url, notes
        case costAmount = "cost_amount"
        case costPeriod = "cost_period"
        case renewalDate = "renewal_date"
        case renewalRepeat = "renewal_repeat"
    }

    init(_ draft: TileDraft) {
        title = draft.title
        url = draft.url
        notes = draft.notes
        costAmount = draft.costAmount
        costPeriod = draft.costPeriod?.rawValue
        renewalDate = draft.renewalDate.map { Tile.dateOnlyFormatter.string(from: $0) }
        renewalRepeat = draft.renewalRepeat?.rawValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
        try container.encode(notes, forKey: .notes)
        try container.encode(costAmount, forKey: .costAmount)
        try container.encode(costPeriod, forKey: .costPeriod)
        try container.encode(renewalDate, forKey: .renewalDate)
        try container.encode(renewalRepeat, forKey: .renewalRepeat)
    }
}
