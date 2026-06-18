package com.yona.app.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.Locale

/**
 * A document attached to a tile (the file lives in Supabase Storage; this is its
 * row in the `attachments` table). Mirrors the iOS Attachment.
 */
@Serializable
data class Attachment(
    val id: String,
    @SerialName("tile_id") val tileId: String,
    val filename: String,
    @SerialName("storage_path") val storagePath: String,
    @SerialName("content_type") val contentType: String? = null,
    @SerialName("size_bytes") val sizeBytes: Long? = null,
    @SerialName("created_at") val createdAt: String,
) {
    /** Human-readable size, e.g. "1.2 MB"; null if unknown. */
    val displaySize: String? get() = sizeBytes?.let { formatBytes(it) }
}

private fun formatBytes(bytes: Long): String {
    if (bytes < 1024) return "$bytes B"
    val kb = bytes / 1024.0
    if (kb < 1024) return String.format(Locale.getDefault(), "%.0f KB", kb)
    return String.format(Locale.getDefault(), "%.1f MB", kb / 1024.0)
}
