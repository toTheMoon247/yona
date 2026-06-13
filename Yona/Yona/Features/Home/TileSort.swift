//
//  TileSort.swift
//  Yona
//
//  How the Home grid is ordered. Tiles missing the relevant value (no due date /
//  no cost) fall to the end, then by most-recently-added.
//

import Foundation

enum TileSort: String, CaseIterable, Identifiable {
    case recentlyAdded
    case dueDate
    case name
    case cost

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recentlyAdded: return "Recently added"
        case .dueDate: return "Due date"
        case .name: return "Name"
        case .cost: return "Cost"
        }
    }

    func sort(_ tiles: [Tile]) -> [Tile] {
        switch self {
        case .recentlyAdded:
            return tiles.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return tiles.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .dueDate:
            return tiles.sorted(by: Self.byDueDate)
        case .cost:
            return tiles.sorted(by: Self.byCost)
        }
    }

    /// Soonest renewal first; tiles without a date go last (then most recent).
    private static func byDueDate(_ lhs: Tile, _ rhs: Tile) -> Bool {
        switch (lhs.nextRenewal, rhs.nextRenewal) {
        case let (left?, right?): return left < right
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return lhs.createdAt > rhs.createdAt
        }
    }

    /// Highest monthly cost first; tiles without a cost go last (then most recent).
    private static func byCost(_ lhs: Tile, _ rhs: Tile) -> Bool {
        switch (lhs.monthlyCost, rhs.monthlyCost) {
        case let (left?, right?): return left > right
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return lhs.createdAt > rhs.createdAt
        }
    }
}
