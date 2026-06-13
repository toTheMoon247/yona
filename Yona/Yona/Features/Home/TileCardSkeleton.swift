//
//  TileCardSkeleton.swift
//  Yona
//
//  Placeholder tile shown while the grid loads — a gently pulsing gray card so
//  the first launch feels alive instead of a blank spinner.
//

import SwiftUI

struct TileCardSkeleton: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.s) {
            Circle()
                .fill(Color.gray.opacity(0.22))
                .frame(width: 56, height: 56)
                .padding(.top, DesignTokens.Spacing.s)

            Capsule()
                .fill(Color.gray.opacity(0.22))
                .frame(width: 72, height: 12)

            Color.clear.frame(height: 16)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.m)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
        )
        .opacity(pulse ? 0.55 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
