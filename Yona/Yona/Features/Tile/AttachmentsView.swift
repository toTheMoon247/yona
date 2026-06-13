//
//  AttachmentsView.swift
//  Yona
//
//  The "Attachments" card on the tile detail screen: lists a tile's documents
//  and lets you add one (pick → upload to Storage). Open/delete arrive in
//  later slices.
//

import SwiftUI
import UniformTypeIdentifiers

struct AttachmentsView: View {
    let tileID: UUID

    @Environment(SupabaseRepository.self) private var repository

    @State private var attachments: LoadState<[Attachment]> = .idle
    @State private var isImporting = false
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text("Attachments").font(.headline)

            content

            Button {
                isImporting = true
            } label: {
                Label("Add document", systemImage: "paperclip")
            }
            .disabled(isUploading)

            if isUploading {
                HStack(spacing: DesignTokens.Spacing.s) {
                    ProgressView()
                    Text("Uploading…").foregroundStyle(.secondary)
                }
                .font(.footnote)
            }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
        )
        .task { await load() }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch attachments {
        case .idle, .loading:
            ProgressView()
        case let .loaded(items):
            if items.isEmpty {
                Text("No documents yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { attachment in
                    row(attachment)
                }
            }
        case .failed:
            Text("Couldn't load documents.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func row(_ attachment: Attachment) -> some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            Image(systemName: "doc.fill").foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.filename).lineLimit(1)
                if let size = attachment.displaySize {
                    Text(size).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func load() async {
        if attachments.value == nil { attachments = .loading }
        do {
            attachments = .loaded(try await repository.fetchAttachments(tileID: tileID))
        } catch {
            attachments = .failed(error)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            Task { await upload(from: url) }
        case .failure:
            errorMessage = "Couldn't read that file."
        }
    }

    private func upload(from url: URL) async {
        errorMessage = nil
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            guard data.count <= 25 * 1024 * 1024 else {
                errorMessage = "That file is over 25 MB."
                return
            }
            isUploading = true
            defer { isUploading = false }

            let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
            let attachment = try await repository.uploadAttachment(
                tileID: tileID,
                data: data,
                filename: url.lastPathComponent,
                contentType: mime
            )
            var current = attachments.value ?? []
            current.insert(attachment, at: 0)
            attachments = .loaded(current)
            Haptics.success()
        } catch {
            #if DEBUG
            print("Attachment upload error:", error)
            errorMessage = "Upload failed: \(error)"
            #else
            errorMessage = "Upload failed. Please try again."
            #endif
        }
    }
}
