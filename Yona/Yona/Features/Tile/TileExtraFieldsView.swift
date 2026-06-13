//
//  TileExtraFieldsView.swift
//  Yona
//
//  The optional "details" form sections (notes, cost, renewal date), shared by
//  the Add flow's second step and the Edit sheet.
//

import SwiftUI

struct TileExtraFieldsView: View {
    @Binding var notes: String
    @Binding var costText: String
    @Binding var costPeriod: CostPeriod
    @Binding var hasRenewalDate: Bool
    @Binding var renewalDate: Date

    var body: some View {
        Section("Notes (optional)") {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
        Section("Cost (optional)") {
            HStack {
                Text(Locale.current.currencySymbol ?? "$")
                    .foregroundStyle(.secondary)
                TextField("Amount", text: $costText)
                    .keyboardType(.decimalPad)
            }
            Picker("Billing", selection: $costPeriod) {
                Text("Monthly").tag(CostPeriod.monthly)
                Text("Yearly").tag(CostPeriod.yearly)
            }
            .pickerStyle(.segmented)
        }
        Section("Renewal date (optional)") {
            Toggle("Set a renewal date", isOn: $hasRenewalDate)
            if hasRenewalDate {
                DatePicker("Renews on", selection: $renewalDate, displayedComponents: .date)
            }
        }
    }
}
