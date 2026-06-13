//
//  TileLogoView.swift
//  Yona
//
//  Shows a tile's brand logo (Brandfetch) on a white circle, falling back to the
//  letter-tile while loading or when no logo is found. An already-fetched logo
//  renders synchronously from cache (no flash) — grid and detail use one size so
//  they share the same cached image.
//

import SwiftUI

struct TileLogoView: View {
    let title: String
    let seed: String
    let websiteURL: String
    var size: Int = 256

    var body: some View {
        if let url = LogoProvider.logoURL(forWebsite: websiteURL, size: size) {
            if let cached = LogoImageCache.image(for: url) {
                logo(Image(uiImage: cached))
            } else {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case let .success(image):
                        logo(image)
                    case .empty, .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            }
        } else {
            fallback
        }
    }

    private func logo(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white)
            .clipShape(Circle())
    }

    private var fallback: some View {
        LetterTileView(title: title, seed: seed)
    }
}
