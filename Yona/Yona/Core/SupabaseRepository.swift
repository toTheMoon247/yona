//
//  SupabaseRepository.swift
//  Yona
//
//  The single seam between the app and Supabase. Stores call into here; nothing
//  else touches the SDK directly.
//

import Foundation
import Observation
import Supabase

enum RepositoryError: Error {
    case notSignedIn
}

@Observable
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

    // MARK: - Attachments

    func fetchAttachments(tileID: UUID) async throws -> [Attachment] {
        try await client
            .from("attachments")
            .select()
            .eq("tile_id", value: tileID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Upload a file to Storage at `{user}/{tile}/{uuid}-{name}` and insert its row.
    func uploadAttachment(tileID: UUID, data: Data, filename: String,
                          contentType: String?) async throws -> Attachment {
        guard let userID = currentUserID else { throw RepositoryError.notSignedIn }
        // Storage RLS compares the first path folder to auth.uid() (lowercase),
        // but Swift's UUID.uuidString is uppercase — lowercase it or uploads 403.
        let path = "\(userID.lowercased())/\(tileID.uuidString.lowercased())/\(UUID().uuidString)-\(filename)"

        try await client.storage
            .from("documents")
            .upload(path, data: data,
                    options: FileOptions(contentType: contentType ?? "application/octet-stream"))

        let payload = AttachmentInsertPayload(
            tileID: tileID.uuidString, filename: filename,
            storagePath: path, contentType: contentType, sizeBytes: data.count
        )
        return try await client
            .from("attachments")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    /// A short-lived signed URL to download a stored file.
    func signedURL(for storagePath: String, expiresIn: Int = 3600) async throws -> URL {
        try await client.storage
            .from("documents")
            .createSignedURL(path: storagePath, expiresIn: expiresIn)
    }

    /// Remove a single attachment: the Storage object first, then its row.
    func deleteAttachment(_ attachment: Attachment) async throws {
        try await client.storage.from("documents").remove(paths: [attachment.storagePath])
        try await client
            .from("attachments")
            .delete()
            .eq("id", value: attachment.id.uuidString)
            .execute()
    }

    /// Sweep a tile's Storage folder (the row cascade doesn't remove the files).
    func deleteTileAttachments(tileID: UUID) async throws {
        guard let userID = currentUserID else { return }
        let folder = "\(userID.lowercased())/\(tileID.uuidString.lowercased())"
        let objects = try await client.storage.from("documents").list(path: folder)
        let paths = objects.map { "\(folder)/\($0.name)" }
        if !paths.isEmpty {
            try await client.storage.from("documents").remove(paths: paths)
        }
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
    let billingSource: String?
    let paymentMethod: String?

    enum CodingKeys: String, CodingKey {
        case title, url, notes
        case costAmount = "cost_amount"
        case costPeriod = "cost_period"
        case renewalDate = "renewal_date"
        case renewalRepeat = "renewal_repeat"
        case billingSource = "billing_source"
        case paymentMethod = "payment_method"
    }

    init(_ draft: TileDraft) {
        title = draft.title
        url = draft.url
        notes = draft.notes
        costAmount = draft.costAmount
        costPeriod = draft.costPeriod?.rawValue
        renewalDate = draft.renewalDate.map { Tile.dateOnlyFormatter.string(from: $0) }
        renewalRepeat = draft.renewalRepeat?.rawValue
        billingSource = draft.billingSource?.rawValue
        paymentMethod = draft.paymentMethod
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
        try container.encode(billingSource, forKey: .billingSource)
        try container.encode(paymentMethod, forKey: .paymentMethod)
    }
}

private struct AttachmentInsertPayload: Encodable {
    let tileID: String
    let filename: String
    let storagePath: String
    let contentType: String?
    let sizeBytes: Int

    enum CodingKeys: String, CodingKey {
        case filename
        case tileID = "tile_id"
        case storagePath = "storage_path"
        case contentType = "content_type"
        case sizeBytes = "size_bytes"
    }
}
