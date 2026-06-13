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

enum RenewalRepeat: String, Codable, CaseIterable, Hashable {
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
    var renewalDate: Date?
    var renewalRepeat: RenewalRepeat?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, url, notes
        case logoURL = "logo_url"
        case costAmount = "cost_amount"
        case costPeriod = "cost_period"
        case renewalDate = "renewal_date"
        case renewalRepeat = "renewal_repeat"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(String.self, forKey: .url)
        logoURL = try container.decodeIfPresent(String.self, forKey: .logoURL)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        costPeriod = try container.decodeIfPresent(CostPeriod.self, forKey: .costPeriod)
        renewalRepeat = try container.decodeIfPresent(RenewalRepeat.self, forKey: .renewalRepeat)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        // `numeric` may arrive as a JSON number or a string depending on the backend.
        if let value = try? container.decodeIfPresent(Double.self, forKey: .costAmount) {
            costAmount = value
        } else if let text = try? container.decodeIfPresent(String.self, forKey: .costAmount) {
            costAmount = Double(text)
        } else {
            costAmount = nil
        }
        // `date` column arrives as "yyyy-MM-dd".
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .renewalDate) {
            renewalDate = Tile.dateOnlyFormatter.date(from: dateString)
        } else {
            renewalDate = nil
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

    /// The next upcoming renewal: a repeating anchor rolled forward to today or
    /// later, or the plain date for a one-time renewal. Nil if unset.
    var nextRenewal: Date? {
        guard let renewalDate else { return nil }
        guard let renewalRepeat else { return renewalDate }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var date = calendar.startOfDay(for: renewalDate)
        let component: Calendar.Component = renewalRepeat == .monthly ? .month : .year
        while date < today {
            guard let next = calendar.date(byAdding: component, value: 1, to: date) else { break }
            date = next
        }
        return date
    }

    /// Whole days from today until the next renewal (negative if past); nil if unset.
    var daysUntilRenewal: Int? {
        guard let next = nextRenewal else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next)).day
    }

    /// Relative phrase for the next renewal ("in 12 days", "today", "3 days ago").
    var renewalRelative: String? {
        guard let days = daysUntilRenewal else { return nil }
        switch days {
        case 0: return "today"
        case 1: return "tomorrow"
        case -1: return "yesterday"
        case let future where future > 0: return "in \(future) days"
        default: return "\(-days) days ago"
        }
    }

    /// Next renewal display, e.g. "Jul 15, 2026 · in 12 days"; nil if unset.
    var renewalSummary: String? {
        guard let next = nextRenewal else { return nil }
        let date = next.formatted(date: .abbreviated, time: .omitted)
        guard let relative = renewalRelative else { return date }
        return "\(date) · \(relative)"
    }

    static var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    /// Parses/formats the Postgres `date` type ("yyyy-MM-dd", calendar date, no zone).
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
