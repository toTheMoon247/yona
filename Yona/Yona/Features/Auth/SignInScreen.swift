//
//  SignInScreen.swift
//  Yona
//

import SwiftUI

struct SignInScreen: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            Spacer()

            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Yona")
                .font(.largeTitle.bold())

            Text("All your important accounts, in one place.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)

            Spacer()

            VStack(spacing: DesignTokens.Spacing.m) {
                Button {
                    Task { await auth.signInWithGoogle() }
                } label: {
                    Label("Continue with Google", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(auth.isAuthenticating)

                Button {
                    // Stub: enabled once the Apple Developer Program is active (Phase 5).
                } label: {
                    Label("Continue with Apple", systemImage: "apple.logo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(true)

                Text("Apple sign-in coming soon")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if auth.isAuthenticating {
                    ProgressView().padding(.top, DesignTokens.Spacing.s)
                }

                if let message = auth.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .padding()
    }
}
