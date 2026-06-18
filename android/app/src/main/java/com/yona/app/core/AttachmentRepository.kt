package com.yona.app.core

import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.storage.storage
import io.ktor.http.ContentType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

/**
 * Documents stored in the private `documents` Storage bucket + their rows in the
 * `attachments` table. RLS/Storage policies are owner-only. Mirrors the iOS repo.
 */
object AttachmentRepository {
    private const val BUCKET = "documents"
    private val columns = Columns.list(
        "id", "tile_id", "filename", "storage_path", "content_type", "size_bytes", "created_at",
    )

    private val bucket get() = Supabase.client.storage.from(BUCKET)
    private val table get() = Supabase.client.postgrest.from("attachments")
    private val userId: String? get() = Supabase.client.auth.currentUserOrNull()?.id

    suspend fun fetchAttachments(tileId: String): List<Attachment> =
        table.select(columns) {
            filter { eq("tile_id", tileId) }
            order("created_at", Order.DESCENDING)
        }.decodeList<Attachment>()

    /** Upload to `{user}/{tile}/{uuid}-{name}` (lowercased folders for Storage RLS) and insert the row. */
    suspend fun uploadAttachment(
        tileId: String,
        data: ByteArray,
        filename: String,
        contentType: String?,
    ): Attachment {
        val uid = userId ?: error("Not signed in")
        val mime = contentType?.let { runCatching { ContentType.parse(it) }.getOrNull() }
            ?: ContentType.Application.OctetStream
        val path = "${uid.lowercase()}/${tileId.lowercase()}/${UUID.randomUUID()}-$filename"

        bucket.upload(path, data) {
            this.contentType = mime
            upsert = false
        }

        val payload = AttachmentInsert(
            tileId = tileId,
            filename = filename,
            storagePath = path,
            contentType = contentType,
            sizeBytes = data.size.toLong(),
        )
        return table.insert(payload) { select(columns) }.decodeSingle<Attachment>()
    }

    /** Download the file bytes using the authenticated session (for previewing). */
    suspend fun downloadAttachment(storagePath: String): ByteArray =
        bucket.downloadAuthenticated(storagePath)

    /** Remove a single attachment: the Storage object first, then its row. */
    suspend fun deleteAttachment(attachment: Attachment) {
        bucket.delete(attachment.storagePath)
        table.delete { filter { eq("id", attachment.id) } }
    }

    /** Sweep a tile's Storage folder (the row cascade doesn't remove the files). */
    suspend fun deleteTileAttachments(tileId: String) {
        val uid = userId ?: return
        val folder = "${uid.lowercase()}/${tileId.lowercase()}"
        val objects = runCatching { bucket.list(folder) }.getOrDefault(emptyList())
        val paths = objects.map { "$folder/${it.name}" }
        if (paths.isNotEmpty()) bucket.delete(paths)
    }
}

@Serializable
private data class AttachmentInsert(
    @SerialName("tile_id") val tileId: String,
    val filename: String,
    @SerialName("storage_path") val storagePath: String,
    @SerialName("content_type") val contentType: String?,
    @SerialName("size_bytes") val sizeBytes: Long,
)
