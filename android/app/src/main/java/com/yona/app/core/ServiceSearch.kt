package com.yona.app.core

import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.isSuccess
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.net.URLEncoder

/**
 * Brandfetch Brand Search — match a typed name to brands (name + domain + icon) so
 * the add flow can auto-fill. Uses the same client ID as the Logo API. Mirrors iOS.
 */
object ServiceSearch {
    private val json = Json { ignoreUnknownKeys = true }
    private val serializer = ListSerializer(BrandResult.serializer())
    private val http by lazy { HttpClient(OkHttp) }

    /** Returns [] when there's no client ID, the query is too short, or on any failure. */
    suspend fun search(query: String): List<BrandResult> {
        val clientId = AppConfig.brandfetchClientId
        if (clientId.isBlank()) return emptyList()
        val trimmed = query.trim()
        if (trimmed.length < 2) return emptyList()
        val encoded = URLEncoder.encode(trimmed, "UTF-8").replace("+", "%20")
        return runCatching {
            val response = http.get("https://api.brandfetch.io/v2/search/$encoded?c=$clientId")
            if (!response.status.isSuccess()) return emptyList()
            json.decodeFromString(serializer, response.bodyAsText())
        }.getOrDefault(emptyList())
    }
}
