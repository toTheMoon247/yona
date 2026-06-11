//
//  AppConfig.swift
//  Yona
//
//  Reads backend configuration from the app's Info.plist, which is fed from an
//  (uncommitted) Secrets.xcconfig. See Secrets.example.xcconfig at the repo root.
//

import Foundation

/// Static app configuration resolved once at launch.
///
/// In Phase 0 there is no Supabase project yet, so when the keys are absent we
/// fall back to a syntactically-valid placeholder URL — the Supabase client can
/// still be constructed and the app launches. Real values arrive in Phase 1 via
/// `Secrets.xcconfig` → Info.plist (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
struct AppConfig {
    let supabaseURL: URL
    let supabaseAnonKey: String

    /// `false` until real Supabase credentials are wired in (Phase 1).
    let isConfigured: Bool

    static let shared = AppConfig()

    init(bundle: Bundle = .main) {
        let info = bundle.infoDictionary
        let urlString = (info?["SUPABASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let key = (info?["SUPABASE_ANON_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !urlString.isEmpty, !key.isEmpty,
           let url = URL(string: urlString), url.host != nil,
           !urlString.contains("YOUR-PROJECT-REF") {
            supabaseURL = url
            supabaseAnonKey = key
            isConfigured = true
        } else {
            supabaseURL = URL(string: "https://placeholder.supabase.co")!
            supabaseAnonKey = "placeholder-anon-key"
            isConfigured = false
        }
    }
}
