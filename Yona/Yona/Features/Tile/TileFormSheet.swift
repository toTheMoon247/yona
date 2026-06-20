//
//  TileFormSheet.swift
//  Yona
//
//  Single-screen editor for an existing tile (title + URL + the optional details).
//  Creating a new tile uses the two-step AddTileFlow instead.
//

import SwiftUI

struct TileFormSheet: View {
    let tile: Tile

    @Environment(TileStore.self) private var tileStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var urlText: String
    @State private var notes: String
    @State private var costText: String
    @State private var costPeriod: CostPeriod
    @State private var hasRenewalDate: Bool
    @State private var renewalDate: Date
    @State private var renewalRepeat: RenewalRepeat?
    @State private var billingSource: BillingSource?
    @State private var paymentMethod: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(tile: Tile) {
        self.tile = tile
        _title = State(initialValue: tile.title)
        _urlText = State(initialValue: tile.url)
        _notes = State(initialValue: tile.notes ?? "")
        _costText = State(initialValue: tile.costAmount.map {
            $0.formatted(.number.precision(.fractionLength(0...2)))
        } ?? "")
        _costPeriod = State(initialValue: tile.costPeriod ?? .monthly)
        _hasRenewalDate = State(initialValue: tile.renewalDate != nil)
        _renewalDate = State(initialValue: tile.renewalDate ?? Date())
        _renewalRepeat = State(initialValue: tile.renewalRepeat)
        _billingSource = State(initialValue: tile.billingSource)
        _paymentMethod = State(initialValue: tile.paymentMethod ?? "")
    }

    /// Trimmed payment method, but only when the billing source uses one
    /// (store-billed subs ignore it) — otherwise nil so nothing is stored.
    private var cleanPaymentMethod: String? {
        guard billingSource?.usesPaymentMethod ?? false else { return nil }
        let trimmed = paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedURL: String { urlText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty && !trimmedURL.isEmpty && !isSaving }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("URL", text: $urlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                TileExtraFieldsView(
                    notes: $notes,
                    costText: $costText,
                    costPeriod: $costPeriod,
                    hasRenewalDate: $hasRenewalDate,
                    renewalDate: $renewalDate,
                    renewalRepeat: $renewalRepeat,
                    billingSource: $billingSource,
                    paymentMethod: $paymentMethod
                )
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(!canSave)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .overlay {
                if isSaving { ProgressView().controlSize(.large) }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let (amount, period) = TileDraft.cost(fromText: costText, period: costPeriod)
        let draft = TileDraft(
            title: trimmedTitle,
            url: URLHelpers.normalized(trimmedURL),
            notes: cleanNotes.isEmpty ? nil : cleanNotes,
            costAmount: amount,
            costPeriod: period,
            renewalDate: hasRenewalDate ? renewalDate : nil,
            renewalRepeat: hasRenewalDate ? renewalRepeat : nil,
            billingSource: billingSource,
            paymentMethod: cleanPaymentMethod
        )

        do {
            try await tileStore.update(id: tile.id, draft)
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = "Couldn't save this tile. Please try again."
        }
    }
}
