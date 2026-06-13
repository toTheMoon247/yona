//
//  AddTileFlow.swift
//  Yona
//
//  Two-step "add a tile" wizard: Step 1 identifies the service (search → title +
//  URL, with a logo confirmation); Step 2 adds the optional details. Create only
//  — editing uses the single-screen TileFormSheet.
//

import SwiftUI

struct AddTileFlow: View {
    @Environment(TileStore.self) private var tileStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var urlText = ""
    @State private var notes = ""
    @State private var costText = ""
    @State private var costPeriod: CostPeriod = .monthly
    @State private var hasRenewalDate = false
    @State private var renewalDate = Date()
    @State private var renewalRepeat: RenewalRepeat?

    @State private var showDetails = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedURL: String { urlText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canContinue: Bool { !trimmedTitle.isEmpty && !trimmedURL.isEmpty }

    var body: some View {
        NavigationStack {
            serviceStep
                .navigationTitle("Add a service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Next") { showDetails = true }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canContinue)
                    }
                }
                .navigationDestination(isPresented: $showDetails) { detailsStep }
        }
    }

    // MARK: - Step 1: identity

    private var serviceStep: some View {
        Form {
            ServiceSearchField(title: $title, urlText: $urlText)
            Section {
                TextField("Title", text: $title)
                TextField("URL", text: $urlText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            if canContinue {
                Section("Selected") { confirmationRow }
            }
        }
    }

    private var confirmationRow: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            TileLogoView(title: trimmedTitle, seed: trimmedURL, websiteURL: trimmedURL)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(trimmedTitle).font(.headline).lineLimit(1)
                Text(displayHost).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    // MARK: - Step 2: details

    private var detailsStep: some View {
        Form {
            TileExtraFieldsView(
                notes: $notes,
                costText: $costText,
                costPeriod: $costPeriod,
                hasRenewalDate: $hasRenewalDate,
                renewalDate: $renewalDate,
                renewalRepeat: $renewalRepeat
            )
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving)
            }
        }
        .interactiveDismissDisabled(isSaving)
        .overlay {
            if isSaving { ProgressView().controlSize(.large) }
        }
    }

    private var displayHost: String {
        guard let host = URL(string: URLHelpers.normalized(trimmedURL))?.host() else { return trimmedURL }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
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
            renewalRepeat: hasRenewalDate ? renewalRepeat : nil
        )

        do {
            try await tileStore.create(draft)
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = "Couldn't save this tile. Please try again."
        }
    }
}
