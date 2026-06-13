//
//  ContentView.swift
//  Yona
//
//  AuthGate: routes between sign-in and the (placeholder) home based on session
//  state, and starts auth observation for the app's lifetime.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        Group {
            switch auth.sessionState {
            case .unknown:
                ProgressView()
                    .controlSize(.large)
            case .signedOut:
                SignInScreen()
            case .signedIn:
                HomeView()
            }
        }
        .animation(.default, value: auth.sessionState)
        .task {
            await auth.observeAuthChanges()
        }
    }
}
