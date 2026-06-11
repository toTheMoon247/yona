//
//  Tile.swift
//  Yona
//
//  A saved online account/service. Minimal for Phase 0; CRUD lands in Phase 2.
//

import Foundation

struct Tile: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var url: String
    var logoURL: String?
    var notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, url, notes
        case logoURL = "logo_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Whether the Home tile should show the note indicator (Option A: single notes field).
    var hasNotes: Bool {
        guard let notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
