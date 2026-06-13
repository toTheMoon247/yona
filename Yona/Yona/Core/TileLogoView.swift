//
//  TileLogoView.swift
//  Yona
//
//  Shows a tile's brand logo (Brandfetch) on a white circle, falling back to the
//  letter-tile while loading or when no logo is found. Uses an explicit loader +
//  in-memory cache so a logo the grid already fetched renders instantly (from the
//  first frame) on the detail screen — no placeholder flash.
//

import SwiftUI

struct TileLogoView: View {
    let title: String
    let seed: String
    let websiteURL: String
    var size: Int = 256

    @State private var loaded: UIImage?
    @State private var didFail = false

    private var url: URL? {
        LogoProvider.logoURL(forWebsite: websiteURL, size: size)
    }

    var body: some View {
        content
            .task(id: url?.absoluteString) { await loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if let image = displayImage {
            logo(Image(uiImage: image))
        } else {
            fallback
        }
    }

    /// Instant in-memory hit (no decode) or the image we just loaded.
    private var displayImage: UIImage? {
        loaded ?? url.flatMap { LogoImageCache.inMemory(for: $0) }
    }

    private func loadIfNeeded() async {
        guard let url, loaded == nil, !didFail else { return }

        // Memory, or decode from disk-cached bytes — both avoid a network round trip.
        if let cached = LogoImageCache.image(for: url) {
            loaded = cached
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let image = UIImage(data: data) else {
                didFail = true
                return
            }
            LogoImageCache.store(image, for: url)
            withAnimation(.easeInOut(duration: 0.2)) { loaded = image }
        } catch {
            didFail = true
        }
    }

    private func logo(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(Circle())
    }

    private var fallback: some View {
        LetterTileView(title: title, seed: seed)
    }
}
