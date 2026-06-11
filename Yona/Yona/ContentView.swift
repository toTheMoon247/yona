//
//  ContentView.swift
//  Yona
//
//  Phase 0 placeholder: confirms the app, stores, and Supabase wiring build and
//  launch. Real routing (AuthGate → SignIn / Home) arrives in Phase 1.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(TileStore.self) private var tiles

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Yona")
                .font(.largeTitle.bold())

            Text("Phase 0 — foundations")
                .foregroundStyle(.secondary)

            Label(
                AppConfig.shared.isConfigured ? "Supabase configured" : "Supabase not configured yet",
                systemImage: AppConfig.shared.isConfigured ? "checkmark.seal.fill" : "wrench.and.screwdriver.fill"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, DesignTokens.Spacing.s)
        }
        .padding()
    }
}

#Preview {
    let repository = SupabaseRepository()
    return ContentView()
        .environment(AuthStore(repository: repository))
        .environment(TileStore(repository: repository))
}
