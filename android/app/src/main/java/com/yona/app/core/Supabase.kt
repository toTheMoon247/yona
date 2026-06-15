package com.yona.app.core

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.storage.Storage

/**
 * The single shared Supabase client. Auth/Postgrest/Storage are installed up front
 * so later phases just use them. The Auth deep-link scheme/host must match the
 * `yona://auth-callback` redirect registered in Supabase (shared with iOS).
 */
object Supabase {

    val client: SupabaseClient by lazy {
        createSupabaseClient(
            supabaseUrl = AppConfig.supabaseUrl,
            supabaseKey = AppConfig.supabaseAnonKey,
        ) {
            install(Auth) {
                scheme = "yona"
                host = "auth-callback"
            }
            install(Postgrest)
            install(Storage)
        }
    }
}
