//
//  ServiceSearchField.swift
//  Yona
//
//  Search a brand by name and auto-fill the tile's title + URL. A debounced
//  Brandfetch Brand Search; picking a result fills the fields (still editable),
//  and there's always the manual path below.
//

import SwiftUI

struct ServiceSearchField: View {
    @Binding var title: String
    @Binding var urlText: String

    @State private var query = ""
    @State private var results: [BrandResult] = []
    @State private var isSearching = false

    var body: some View {
        Section {
            TextField("Search for a service", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .task(id: query) { await runSearch() }

            if isSearching {
                HStack(spacing: DesignTokens.Spacing.s) {
                    ProgressView()
                    Text("Searching…").foregroundStyle(.secondary)
                }
            }

            ForEach(results) { result in
                Button {
                    select(result)
                } label: {
                    row(result)
                }
                .buttonStyle(.plain)
            }

            if showNoResults {
                Text("No matches — fill in the details below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Find a service")
        } footer: {
            Text("Search a brand to auto-fill its name, link, and logo — or just fill in the details below.")
        }
    }

    private var showNoResults: Bool {
        !isSearching && results.isEmpty
            && query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    private func row(_ result: BrandResult) -> some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            AsyncImage(url: result.icon.flatMap { URL(string: $0) }) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Image(systemName: "globe").foregroundStyle(.secondary)
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(result.displayName).foregroundStyle(.primary)
                Text(result.domain).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func select(_ result: BrandResult) {
        title = result.displayName
        urlText = result.domain
        query = ""
        results = []
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }
        try? await Task.sleep(for: .milliseconds(300))
        if Task.isCancelled { return }
        isSearching = true
        let found = (try? await BrandSearch.search(trimmed)) ?? []
        if Task.isCancelled { return }
        results = found
        isSearching = false
    }
}
