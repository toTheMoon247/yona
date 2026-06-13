//
//  TileDraft.swift
//  Yona
//
//  The editable fields of a tile, bundled together for create/update so the
//  repository and store don't pass them around as a long parameter list.
//

import Foundation

struct TileDraft {
    var title: String
    var url: String
    var notes: String?
    var costAmount: Double?
    var costPeriod: CostPeriod?
    var renewalDate: Date?

    /// Parse the cost field: returns (nil, nil) when empty/invalid.
    static func cost(fromText text: String, period: CostPeriod) -> (amount: Double?, period: CostPeriod?) {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        if let amount = Double(normalized), amount > 0 {
            return (amount, period)
        }
        return (nil, nil)
    }
}
