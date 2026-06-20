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
    @Binding var renewalRepeat: RenewalRepeat?
    @Binding var billingSource: BillingSource?
    @Binding var paymentMethod: String

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
        billingSection
        renewalSection
    }

    /// "How it's paid": where it's billed (lead) + an optional payment method that
    /// only applies to non-store sources. We store a card type + last 4 only.
    private var billingSection: some View {
        Section {
            Picker("Billed through", selection: $billingSource) {
                Text("Not set").tag(BillingSource?.none)
                ForEach(BillingSource.allCases) { source in
                    Text(source.label).tag(BillingSource?.some(source))
                }
            }
            if billingSource?.usesPaymentMethod ?? false {
                TextField("Payment method (e.g. Visa ••1234)", text: $paymentMethod)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
        } header: {
            Text("How it's paid (optional)")
        } footer: {
            if billingSource?.usesPaymentMethod ?? false {
                Text("For your reference only — enter a card type and the last 4 digits. Never store full card numbers.")
            } else {
                Text("Where this subscription is billed, so you know where to cancel or manage it.")
            }
        }
    }

    private var renewalSection: some View {
        Section("Renewal date (optional)") {
            Toggle("Set a renewal date", isOn: $hasRenewalDate)
                .onChange(of: hasRenewalDate) { _, isOn in
                    applyRepeatDefault(isOn: isOn)
                }
            if hasRenewalDate {
                HStack {
                    Button("Today") { setRenewal(months: 0, years: 0) }
                    Button("+1 month") { setRenewal(months: 1, years: 0) }
                    Button("+1 year") { setRenewal(months: 0, years: 1) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                DatePicker("Renews on", selection: $renewalDate, displayedComponents: .date)

                Picker("Repeats", selection: $renewalRepeat) {
                    Text("Never").tag(RenewalRepeat?.none)
                    Text("Monthly").tag(RenewalRepeat?.some(.monthly))
                    Text("Yearly").tag(RenewalRepeat?.some(.yearly))
                }
            }
        }
    }

    private func setRenewal(months: Int, years: Int) {
        let calendar = Calendar.current
        var date = Date()
        if months != 0 { date = calendar.date(byAdding: .month, value: months, to: date) ?? date }
        if years != 0 { date = calendar.date(byAdding: .year, value: years, to: date) ?? date }
        renewalDate = date
        Haptics.tap()
    }

    /// When the renewal date is switched on and a cost is set, default "Repeats" to match it.
    private func applyRepeatDefault(isOn: Bool) {
        guard isOn, renewalRepeat == nil,
              !costText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        renewalRepeat = costPeriod == .monthly ? .monthly : .yearly
    }
}
