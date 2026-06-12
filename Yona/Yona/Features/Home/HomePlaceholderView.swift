//
//  HomePlaceholderView.swift
//  Yona
//
//  Temporary signed-in landing screen so we can verify the full auth loop
//  (sign in → land here → sign out). The real tile grid arrives in Phase 2.
//

import SwiftUI

struct HomePlaceholderView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.l) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("You're signed in 🎉")
                    .font(.title2.bold())

                Text("The tile grid arrives in Phase 2.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Yona")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Sign out", role: .destructive) {
                            Task { await auth.signOut() }
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
    }
}
