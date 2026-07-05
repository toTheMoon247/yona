//
//  AttachmentsView.swift
//  Yona
//
//  The "Attachments" card on the tile detail screen: lists a tile's documents
//  and lets you add one (pick → upload to Storage). Open/delete arrive in
//  later slices.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import QuickLook

struct AttachmentsView: View {
    let tileID: UUID

    @Environment(SupabaseRepository.self) private var repository

    @State private var attachments: LoadState<[Attachment]> = .idle
    @State private var showingSourceDialog = false
    @State private var isImporting = false
    @State private var showingPhotos = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var openingID: UUID?
    @State private var previewURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text("Attachments").font(.headline)

            content

            Button {
                showingSourceDialog = true
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
        .confirmationDialog("Add a document", isPresented: $showingSourceDialog, titleVisibility: .visible) {
            Button("Choose from Photos") { showingPhotos = true }
            Button("Choose from Files") { isImporting = true }
        }
        .photosPicker(isPresented: $showingPhotos, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await uploadPhoto(item) }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .quickLookPreview($previewURL)
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
        Button {
            Task { await open(attachment) }
        } label: {
            HStack(spacing: DesignTokens.Spacing.m) {
                Image(systemName: "doc.fill").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attachment.filename).lineLimit(1).foregroundStyle(.primary)
                    if let size = attachment.displaySize {
                        Text(size).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if openingID == attachment.id {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(openingID != nil)
        .padding(.vertical, 2)
        .contextMenu {
            Button(role: .destructive) {
                Task { await remove(attachment) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func remove(_ attachment: Attachment) async {
        errorMessage = nil
        do {
            try await repository.deleteAttachment(attachment)
            if var current = attachments.value {
                current.removeAll { $0.id == attachment.id }
                attachments = .loaded(current)
            }
            Haptics.success()
        } catch {
            #if DEBUG
            errorMessage = "Couldn't delete: \(error)"
            #else
            errorMessage = "Couldn't delete this document."
            #endif
        }
    }

    private func load() async {
        if attachments.value == nil { attachments = .loading }
        do {
            attachments = .loaded(try await repository.fetchAttachments(tileID: tileID))
        } catch {
            attachments = .failed(error)
        }
    }

    private func open(_ attachment: Attachment) async {
        errorMessage = nil
        openingID = attachment.id
        defer { openingID = nil }
        do {
            let signed = try await repository.signedURL(for: attachment.storagePath)
            let (data, _) = try await URLSession.shared.data(from: signed)
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(attachment.filename)
            try data.write(to: fileURL, options: .atomic)
            previewURL = fileURL
        } catch {
            #if DEBUG
            errorMessage = "Couldn't open: \(error)"
            #else
            errorMessage = "Couldn't open this document."
            #endif
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
            let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
            await upload(data: data, filename: url.lastPathComponent, contentType: mime)
        } catch {
            errorMessage = "Couldn't read that file."
        }
    }

    private func uploadPhoto(_ item: PhotosPickerItem) async {
        errorMessage = nil
        defer { photoItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Couldn't read that photo."
                return
            }
            let type = item.supportedContentTypes.first
            let ext = type?.preferredFilenameExtension ?? "jpg"
            let mime = type?.preferredMIMEType ?? "image/jpeg"
            let filename = "Photo-\(Self.photoNameFormatter.string(from: Date())).\(ext)"
            await upload(data: data, filename: filename, contentType: mime)
        } catch {
            errorMessage = "Couldn't read that photo."
        }
    }

    /// Core upload shared by the Files and Photos paths (with the 25 MB cap).
    private func upload(data: Data, filename: String, contentType: String?) async {
        guard data.count <= 25 * 1024 * 1024 else {
            errorMessage = "That file is over 25 MB."
            return
        }
        isUploading = true
        defer { isUploading = false }
        do {
            let attachment = try await repository.uploadAttachment(
                tileID: tileID,
                data: data,
                filename: filename,
                contentType: contentType
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

    private static let photoNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}
