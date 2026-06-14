package com.yona.app.core

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.storage.Storage
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.statement.HttpResponse
import io.ktor.http.isSuccess

/**
 * The single shared Supabase client for the app, plus a lightweight connectivity
 * check. Auth/Postgrest/Storage are installed up front so later phases just use them.
 */
object Supabase {

    val client: SupabaseClient by lazy {
        createSupabaseClient(
            supabaseUrl = AppConfig.supabaseUrl,
            supabaseKey = AppConfig.supabaseAnonKey,
        ) {
            install(Auth)
            install(Postgrest)
            install(Storage)
        }
    }

    /**
     * Confirms we can actually reach the backend: builds the client (so a bad
     * config surfaces) and pings the public GoTrue health endpoint with the anon key.
     */
    suspend fun checkConnection(): Result<Unit> = runCatching {
        require(AppConfig.isConfigured) { "Supabase credentials are missing." }
        // Force client creation so any misconfiguration throws here.
        client

        val http = HttpClient(OkHttp)
        try {
            val response: HttpResponse = http.get("${AppConfig.supabaseUrl}/auth/v1/health") {
                header("apikey", AppConfig.supabaseAnonKey)
            }
            check(response.status.isSuccess()) { "Backend returned ${response.status}" }
        } finally {
            http.close()
        }
    }
}
