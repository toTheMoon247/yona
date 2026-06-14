package com.yona.app.core

import com.yona.app.BuildConfig

/**
 * App configuration backed by generated [BuildConfig] fields, which are populated
 * at build time from the git-ignored `secrets.properties` (see the app build script).
 * Mirrors the iOS app's `AppConfig` reading from the bundled `Supabase.plist`.
 */
object AppConfig {
    val supabaseUrl: String = BuildConfig.SUPABASE_URL
    val supabaseAnonKey: String = BuildConfig.SUPABASE_ANON_KEY
    val brandfetchClientId: String = BuildConfig.BRANDFETCH_CLIENT_ID

    /** True only when real Supabase credentials are present (not a placeholder/empty). */
    val isConfigured: Boolean
        get() = supabaseUrl.isNotBlank() &&
            supabaseAnonKey.isNotBlank() &&
            !supabaseUrl.contains("YOUR-PROJECT", ignoreCase = true)

    /** Host portion of the Supabase URL, for display (e.g. `rxjw….supabase.co`). */
    val supabaseHost: String
        get() = supabaseUrl
            .removePrefix("https://")
            .removePrefix("http://")
            .substringBefore("/")
}
