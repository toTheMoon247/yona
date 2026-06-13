//
//  TileFormSheet.swift
//  Yona
//
//  One form for both creating and editing a tile. Title + URL required, notes
//  optional. On save it inserts/updates and dismisses; on failure it stays open.
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
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _urlText = State(initialValue: "")
            _notes = State(initialValue: "")
        case let .edit(tile):
            _title = State(initialValue: tile.title)
            _urlText = State(initialValue: tile.url)
            _notes = State(initialValue: tile.notes ?? "")
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
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
                Section("Notes (optional)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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

        do {
            switch mode {
            case .create:
                try await tileStore.create(title: trimmedTitle, url: finalURL, notes: finalNotes)
            case let .edit(tile):
                try await tileStore.update(id: tile.id, title: trimmedTitle, url: finalURL, notes: finalNotes)
            }
            dismiss()
        } catch {
            errorMessage = "Couldn't save this tile. Please try again."
        }
    }
}
