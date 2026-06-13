//
//  TileFormSheet.swift
//  Yona
//
//  One form for both creating and editing a tile. Title + URL required; notes
//  and cost optional. On save it inserts/updates and dismisses; on failure it
//  stays open with an error.
//

import SwiftUI

struct TileFormSheet: View {
    enum Mode {
        case create
        case edit(Tile)
    }

    let mode: Mode

    @Environment(TileStore.self) private var tileStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var urlText: String
    @State private var notes: String
    @State private var costText: String
    @State private var costPeriod: CostPeriod
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _urlText = State(initialValue: "")
            _notes = State(initialValue: "")
            _costText = State(initialValue: "")
            _costPeriod = State(initialValue: .monthly)
        case let .edit(tile):
            _title = State(initialValue: tile.title)
            _urlText = State(initialValue: tile.url)
            _notes = State(initialValue: tile.notes ?? "")
            _costText = State(initialValue: tile.costAmount.map {
                $0.formatted(.number.precision(.fractionLength(0...2)))
            } ?? "")
            _costPeriod = State(initialValue: tile.costPeriod ?? .monthly)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedURL: String { urlText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty && !trimmedURL.isEmpty && !isSaving }

    /// Parsed (amount, period) from the cost field — both nil when empty/invalid.
    private var parsedCost: (amount: Double?, period: CostPeriod?) {
        let normalized = costText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        if let amount = Double(normalized), amount > 0 {
            return (amount, costPeriod)
        }
        return (nil, nil)
    }

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
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Tile" : "New Tile")
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
                if isSaving {
                    ProgressView().controlSize(.large)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes: String? = cleanNotes.isEmpty ? nil : cleanNotes
        let finalURL = URLHelpers.normalized(trimmedURL)
        let (amount, period) = parsedCost

        do {
            switch mode {
            case .create:
                try await tileStore.create(title: trimmedTitle, url: finalURL, notes: finalNotes,
                                           costAmount: amount, costPeriod: period)
            case let .edit(tile):
                try await tileStore.update(id: tile.id, title: trimmedTitle, url: finalURL,
                                           notes: finalNotes, costAmount: amount, costPeriod: period)
            }
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = "Couldn't save this tile. Please try again."
        }
    }
}
