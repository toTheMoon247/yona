//
//  AppConfig.swift
//  Yona
//
//  Reads backend configuration from a bundled, git-ignored `Supabase.plist`
//  (template: Supabase.example.plist at the repo root). The file ships inside
//  the app but is never committed — RLS is what actually guards the data.
//

import Foundation

/// Static app configuration resolved once at launch.
///
/// When `Supabase.plist` is missing or still has placeholder values (e.g. on CI,
/// where it's git-ignored), we fall back to a syntactically-valid placeholder so
/// the app still builds and launches; `isConfigured` is then `false`.
struct AppConfig {
    let supabaseURL: URL
    let supabaseAnonKey: String

    /// `false` until a real `Supabase.plist` is present.
    let isConfigured: Bool

    static let shared = AppConfig()

    init(bundle: Bundle = .main) {
        var urlString = ""
        var key = ""

        if let plistURL = bundle.url(forResource: "Supabase", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: plistURL) {
            urlString = (dict["SUPABASE_URL"] as? String) ?? ""
            key = (dict["SUPABASE_ANON_KEY"] as? String) ?? ""
        }

        urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        key = key.trimmingCharacters(in: .whitespacesAndNewlines)

        if !urlString.isEmpty, !key.isEmpty,
           !urlString.contains("YOUR-REF"),
           let url = URL(string: urlString), url.host != nil {
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
