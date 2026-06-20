//
//  SignInScreen.swift
//  Yona
//

import AuthenticationServices
import SwiftUI

struct SignInScreen: View {
    @Environment(AuthStore.self) private var auth

    @State private var currentNonce: String?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            Spacer()

            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Yona")
                .font(.largeTitle.bold())

            Text("All your subscriptions, in one place.")
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

                SignInWithAppleButton(.continue) { request in
                    let nonce = NonceGenerator.random()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = NonceGenerator.sha256(nonce)
                } onCompletion: { result in
                    handleAppleResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous))
                .disabled(auth.isAuthenticating)

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

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else { return }
            Task { await auth.signInWithApple(idToken: idToken, nonce: nonce) }
        case let .failure(error):
            // User cancelled or closed the sheet — not a real error.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
        }
    }
}
