//
//  Tile.swift
//  Yona
//
//  A saved online account/service.
//

import Foundation

/// How often a subscription is billed. Stored as a snake_case string in Postgres.
enum CostPeriod: String, Codable, CaseIterable, Hashable {
    case weekly
    case monthly
    case everyTwoMonths = "every_two_months"
    case quarterly
    case everySixMonths = "every_six_months"
    case yearly

    /// How many times a year this period bills — used to annualize a cost.
    var timesPerYear: Double {
        switch self {
        case .weekly: return 52
        case .monthly: return 12
        case .everyTwoMonths: return 6
        case .quarterly: return 4
        case .everySixMonths: return 2
        case .yearly: return 1
        }
    }

    /// Picker label, e.g. "Every 2 months".
    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .everyTwoMonths: return "Every 2 months"
        case .quarterly: return "Quarterly"
        case .everySixMonths: return "Every 6 months"
        case .yearly: return "Yearly"
        }
    }

    /// Suffix for a cost line, e.g. "/ month", "/ 2 months".
    var costSuffix: String {
        switch self {
        case .weekly: return "/ week"
        case .monthly: return "/ month"
        case .everyTwoMonths: return "/ 2 months"
        case .quarterly: return "/ quarter"
        case .everySixMonths: return "/ 6 months"
        case .yearly: return "/ year"
        }
    }
}

/// How often a renewal/due date recurs — parallels `CostPeriod` (same raw values).
enum RenewalRepeat: String, Codable, CaseIterable, Hashable {
    case weekly
    case monthly
    case everyTwoMonths = "every_two_months"
    case quarterly
    case everySixMonths = "every_six_months"
    case yearly

    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .everyTwoMonths: return "Every 2 months"
        case .quarterly: return "Quarterly"
        case .everySixMonths: return "Every 6 months"
        case .yearly: return "Yearly"
        }
    }

    /// The calendar step to roll a recurring date forward.
    var step: (component: Calendar.Component, value: Int) {
        switch self {
        case .weekly: return (.day, 7)
        case .monthly: return (.month, 1)
        case .everyTwoMonths: return (.month, 2)
        case .quarterly: return (.month, 3)
        case .everySixMonths: return (.month, 6)
        case .yearly: return (.year, 1)
        }
    }
}

/// Where a subscription is billed — the most useful "how it's paid" fact, since it
/// tells you where to cancel/manage it. Stored as a snake_case string in Postgres.
enum BillingSource: String, Codable, CaseIterable, Identifiable, Hashable {
    case appStore = "app_store"
    case googlePlay = "google_play"
    case direct
    case bank
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .appStore: return "App Store"
        case .googlePlay: return "Google Play"
        case .direct: return "Direct (website)"
        case .bank: return "Bank debit"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .appStore: return "apple.logo"
        case .googlePlay: return "play.circle"
        case .direct: return "globe"
        case .bank: return "building.columns"
        case .other: return "creditcard"
        }
    }

    /// Store-billed sources charge whatever card is on the store account, so a
    /// per-subscription payment method doesn't apply.
    var usesPaymentMethod: Bool { self != .appStore && self != .googlePlay }
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
    var billingSource: BillingSource?
    var paymentMethod: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, url, notes
        case logoURL = "logo_url"
        case costAmount = "cost_amount"
        case costPeriod = "cost_period"
        case renewalDate = "renewal_date"
        case renewalRepeat = "renewal_repeat"
        case billingSource = "billing_source"
        case paymentMethod = "payment_method"
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
        billingSource = try container.decodeIfPresent(BillingSource.self, forKey: .billingSource)
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod)
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

    /// Cost annualized (amount × times-per-year) for spend totals; nil if no cost.
    var annualizedCost: Double? {
        guard let costAmount, let costPeriod else { return nil }
        return costAmount * costPeriod.timesPerYear
    }

    /// Cost normalized to a monthly figure for summaries/sorting; nil if no cost.
    var monthlyCost: Double? {
        guard let annualizedCost else { return nil }
        return annualizedCost / 12
    }

    /// Display string like "$15.00 / month" or "$60.00 / 2 months"; nil if no cost set.
    var formattedCost: String? {
        guard let costAmount, let costPeriod else { return nil }
        let amount = costAmount.formatted(.currency(code: Self.currencyCode))
        return "\(amount) \(costPeriod.costSuffix)"
    }

    /// The next upcoming renewal: a repeating anchor rolled forward to today or
    /// later, or the plain date for a one-time renewal. Nil if unset.
    var nextRenewal: Date? {
        guard let renewalDate else { return nil }
        guard let renewalRepeat else { return renewalDate }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var date = calendar.startOfDay(for: renewalDate)
        let step = renewalRepeat.step
        while date < today {
            guard let next = calendar.date(byAdding: step.component, value: step.value, to: date) else { break }
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
