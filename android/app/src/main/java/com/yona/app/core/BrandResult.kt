package com.yona.app.core

import kotlinx.serialization.Serializable

/** A Brandfetch Brand Search hit: a brand's name, domain, and icon URL. */
@Serializable
data class BrandResult(
    val name: String? = null,
    val domain: String,
    val icon: String? = null,
) {
    /** Brand name, or a capitalized fallback derived from the domain. */
    val displayName: String
        get() {
            if (!name.isNullOrEmpty()) return name
            val main = domain.substringBefore(".")
            return main.replaceFirstChar { it.uppercase() }
        }
}
