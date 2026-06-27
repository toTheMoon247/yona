//
//  CostBreakdownView.swift
//  Yona
//
//  Tap the spend total on Home → a per-subscription cost breakdown: every paid
//  subscription, normalized to the chosen unit (month/year), sorted high → low,
//  each with its share of the total. Roadmap #8.
//

import SwiftUI

struct CostBreakdownView: View {
    @Environment(TileStore.self) private var tileStore
    @AppStorage("spendShowsMonthly") private var spendShowsMonthly = false

    var body: some View {
        let items = (tileStore.tiles.value ?? []).filter { $0.annualizedCost != nil }
        let totalAnnual = items.compactMap(\.annualizedCost).reduce(0, +)
        let sorted = items.sorted { ($0.annualizedCost ?? 0) > ($1.annualizedCost ?? 0) }
        let code = Tile.currencyCode
        let displayTotal = spendShowsMonthly ? totalAnnual / 12 : totalAnnual

        List {
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                    (
                        Text("You pay ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        + Text(displayTotal.formatted(.currency(code: code)))
                            .font(.largeTitle.bold())
                        + Text(spendShowsMonthly ? " a month" : " a year")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    )
                    .contentTransition(.numericText())
                    Picker("Show spending per", selection: $spendShowsMonthly) {
                        Text("Monthly").tag(true)
                        Text("Yearly").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
                .animation(.snappy, value: spendShowsMonthly)
            }

            Section("By subscription") {
                ForEach(sorted) { tile in
                    NavigationLink(value: tile) {
                        row(tile, totalAnnual: totalAnnual, code: code)
                    }
                }
            }
        }
        .navigationTitle("Spending")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ tile: Tile, totalAnnual: Double, code: String) -> some View {
        let perItem = spendShowsMonthly ? (tile.monthlyCost ?? 0) : (tile.annualizedCost ?? 0)
        let share = totalAnnual > 0 ? (tile.annualizedCost ?? 0) / totalAnnual : 0

        return HStack(spacing: DesignTokens.Spacing.m) {
            TileLogoView(title: tile.title, seed: tile.id.uuidString, websiteURL: tile.url)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(tile.title)
                    .lineLimit(1)
                // The actual billing, e.g. "£180.00 / year" or "£10.00 / 2 months".
                if let billed = tile.formattedCost {
                    Text(billed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.s)

            VStack(alignment: .trailing, spacing: 2) {
                Text(perItem.formatted(.currency(code: code)) + (spendShowsMonthly ? "/mo" : "/yr"))
                    .font(.callout.weight(.medium))
                Text("\(Int((share * 100).rounded()))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
