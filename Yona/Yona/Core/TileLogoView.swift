//
//  TileLogoView.swift
//  Yona
//
//  Shows a tile's brand logo (Brandfetch) on a white circle, falling back to the
//  letter-tile while loading or when no logo is found.
//

import SwiftUI

struct TileLogoView: View {
    let title: String
    let seed: String
    let websiteURL: String
    var size: Int = 128

    var body: some View {
        if let url = LogoProvider.logoURL(forWebsite: websiteURL, size: size) {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.white)
                        .clipShape(Circle())
                case .empty, .failure:
                    fallback
                @unknown default:
                    fallback
                }
            }
        } else {
            fallback
        }
    }

    private var fallback: some View {
        LetterTileView(title: title, seed: seed)
    }
}
