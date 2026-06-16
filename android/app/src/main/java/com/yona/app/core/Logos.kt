package com.yona.app.core

/**
 * Builds Brandfetch Logo API URLs from a tile's website. `fallback/404` makes
 * Brandfetch return 404 on a miss, so the image load fails cleanly and callers
 * show the letter-tile fallback. Mirrors the iOS URLHelpers.domain + LogoProvider.
 */
object Logos {

    /**
     * The host of a URL, lowercased and without a leading `www.` — e.g.
     * `https://www.netflix.com/browse` → `netflix.com`. Null when there's no host.
     * Pure string parsing (no android.net.Uri) so it's unit-testable.
     */
    fun domain(rawUrl: String): String? {
        val normalized = UrlHelpers.normalized(rawUrl)
        if (normalized.isBlank()) return null
        val host = normalized
            .substringAfter("://", normalized)
            .substringBefore('/')
            .substringBefore('?')
            .substringBefore('#')
            .substringBefore(':') // strip any port
            .trim()
            .lowercase()
        if (host.isEmpty()) return null
        return host.removePrefix("www.").ifEmpty { null }
    }

    /** A Brandfetch icon URL for the given website, or null if no domain / no client id. */
    fun brandfetchUrl(website: String, size: Int = 512): String? {
        val domain = domain(website) ?: return null
        val clientId = AppConfig.brandfetchClientId
        if (clientId.isBlank()) return null
        return "https://cdn.brandfetch.io/$domain/icon/fallback/404/w/$size/h/$size?c=$clientId"
    }

    /** The site's favicon via Google's service — fallback for brands Brandfetch misses. */
    fun faviconUrl(website: String, size: Int = 128): String? {
        val domain = domain(website) ?: return null
        return "https://www.google.com/s2/favicons?domain=$domain&sz=$size"
    }
}
