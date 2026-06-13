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
}
