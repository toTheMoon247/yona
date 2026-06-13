//
//  Tile.swift
//  Yona
//
//  A saved online account/service.
//

import Foundation

enum CostPeriod: String, Codable, CaseIterable, Hashable {
    case monthly
    case yearly
}

struct Tile: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var url: String
    var logoURL: String?
    var notes: String?
    var costAmount: Double?
    var costPeriod: CostPeriod?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, url, notes
        case logoURL = "logo_url"
        case costAmount = "cost_amount"
        case costPeriod = "cost_period"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        url = try c.decode(String.self, forKey: .url)
        logoURL = try c.decodeIfPresent(String.self, forKey: .logoURL)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        costPeriod = try c.decodeIfPresent(CostPeriod.self, forKey: .costPeriod)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        // `numeric` may arrive as a JSON number or a string depending on the backend.
        if let value = try? c.decodeIfPresent(Double.self, forKey: .costAmount) {
            costAmount = value
        } else if let text = try? c.decodeIfPresent(String.self, forKey: .costAmount) {
            costAmount = Double(text)
        } else {
            costAmount = nil
        }
    }

    /// Whether the Home tile should show the note indicator (Option A: single notes field).
    var hasNotes: Bool {
        guard let notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Cost normalized to a monthly figure (yearly ÷ 12) for summaries; nil if no cost.
    var monthlyCost: Double? {
        guard let costAmount, let costPeriod else { return nil }
        return costPeriod == .yearly ? costAmount / 12 : costAmount
    }

    /// Display string like "$15.00 / month", or nil if no cost set.
    var formattedCost: String? {
        guard let costAmount, let costPeriod else { return nil }
        let amount = costAmount.formatted(.currency(code: Self.currencyCode))
        return "\(amount) / \(costPeriod == .monthly ? "month" : "year")"
    }

    static var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
