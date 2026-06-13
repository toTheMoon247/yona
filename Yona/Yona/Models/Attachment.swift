//
//  Attachment.swift
//  Yona
//
//  A document attached to a tile (the file lives in Supabase Storage; this is
//  its row in the `attachments` table).
//

import Foundation

struct Attachment: Identifiable, Decodable, Hashable {
    let id: UUID
    let tileId: UUID
    let filename: String
    let storagePath: String
    let contentType: String?
    let sizeBytes: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, filename
        case tileId = "tile_id"
        case storagePath = "storage_path"
        case contentType = "content_type"
        case sizeBytes = "size_bytes"
        case createdAt = "created_at"
    }

    /// Human-readable size, e.g. "1.2 MB"; nil if unknown.
    var displaySize: String? {
        guard let sizeBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }
}
