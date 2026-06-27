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
            ChipFlow(spacing: 8) {
                ForEach(CostPeriod.allCases, id: \.self) { period in
                    SelectableChip(text: period.label, isSelected: costPeriod == period) {
                        costPeriod = period
                    }
                }
            }
        }
        billingSection
        renewalSection
    }

    /// "How it's paid": where it's billed (lead) + an optional payment method that
    /// only applies to non-store sources. We store a card type + last 4 only.
    private var billingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Billed through")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ChipFlow(spacing: 8) {
                    SelectableChip(text: "Not set", isSelected: billingSource == nil) {
                        billingSource = nil
                    }
                    ForEach(BillingSource.allCases) { source in
                        SelectableChip(text: source.label, isSelected: billingSource == source) {
                            billingSource = source
                        }
                    }
                }
            }
            .padding(.vertical, 2)
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
                    ForEach(RenewalRepeat.allCases, id: \.self) { option in
                        Text(option.label).tag(RenewalRepeat?.some(option))
                    }
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

    /// When the renewal date is switched on and a cost is set, default "Repeats" to match
    /// the billing cadence (the two enums share raw values).
    private func applyRepeatDefault(isOn: Bool) {
        guard isOn, renewalRepeat == nil,
              !costText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        renewalRepeat = RenewalRepeat(rawValue: costPeriod.rawValue)
    }
}

/// A single-select "chip" — a tappable pill that fills with the accent when selected.
/// Used in place of a dropdown so every choice stays visible.
struct SelectableChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// A simple wrapping layout: lays children left-to-right, wrapping to the next line
/// when the row is full. Lets a row of chips flow onto multiple lines.
struct ChipFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: maxWidth == .infinity ? widest : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
