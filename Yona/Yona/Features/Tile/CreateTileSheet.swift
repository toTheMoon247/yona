//
//  CreateTileSheet.swift
//  Yona
//
//  Form to add a new tile. Title + URL required; notes optional. On save it
//  inserts the tile and dismisses; on failure it stays open with an error.
//

import SwiftUI

struct CreateTileSheet: View {
    @Environment(TileStore.self) private var tileStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var urlText = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedURL: String {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool {
        !trimmedTitle.isEmpty && !trimmedURL.isEmpty && !isSaving
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
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Tile")
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

        do {
            let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            try await tileStore.create(
                title: trimmedTitle,
                url: URLHelpers.normalized(trimmedURL),
                notes: cleanNotes.isEmpty ? nil : cleanNotes
            )
            dismiss()
        } catch {
            errorMessage = "Couldn't save this tile. Please try again."
        }
    }
}
