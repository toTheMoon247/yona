//
//  AppConfig.swift
//  Yona
//
//  Reads configuration from a bundled, git-ignored `Supabase.plist` (template:
//  Supabase.example.plist at the repo root). The file ships inside the app but
//  is never committed — RLS guards the data; the Brandfetch ID is public-by-design.
//

import Foundation

struct AppConfig {
    let supabaseURL: URL
    let supabaseAnonKey: String

    /// `false` until a real `Supabase.plist` is present.
    let isConfigured: Bool

    /// Brandfetch Logo API client ID; nil when unset (logos fall back to letter-tiles).
    let brandfetchClientID: String?

    static let shared = AppConfig()

    init(bundle: Bundle = .main) {
        var urlString = ""
        var key = ""
        var brandfetch: String?

        if let plistURL = bundle.url(forResource: "Supabase", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: plistURL) {
            urlString = (dict["SUPABASE_URL"] as? String) ?? ""
            key = (dict["SUPABASE_ANON_KEY"] as? String) ?? ""
            let bf = ((dict["BRANDFETCH_CLIENT_ID"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            brandfetch = (bf.isEmpty || bf.contains("YOUR-")) ? nil : bf
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

        brandfetchClientID = brandfetch
    }
}
