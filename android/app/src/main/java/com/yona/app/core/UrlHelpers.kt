package com.yona.app.core

object UrlHelpers {
    /**
     * Light normalization for user-entered URLs: trims whitespace and prepends
     * `https://` when no scheme is present. Mirrors the iOS URLHelpers.
     */
    fun normalized(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return trimmed
        val lower = trimmed.lowercase()
        return if (lower.startsWith("http://") || lower.startsWith("https://")) {
            trimmed
        } else {
            "https://$trimmed"
        }
    }
}
