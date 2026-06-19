package com.yona.app.ui

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yona.app.BuildConfig
import com.yona.app.core.Attachment
import com.yona.app.core.AttachmentRepository
import com.yona.app.core.LoadState
import androidx.core.content.FileProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

private const val MAX_BYTES = 25 * 1024 * 1024

/**
 * The "Attachments" card on the tile detail screen: lists a tile's documents and
 * lets you add one (pick → upload to Storage). Mirrors the iOS AttachmentsView.
 */
@Composable
fun AttachmentsView(tileId: String, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current

    var state by remember { mutableStateOf<LoadState<List<Attachment>>>(LoadState.Idle) }
    var uploading by remember { mutableStateOf(false) }
    var openingId by remember { mutableStateOf<String?>(null) }
    var pendingDelete by remember { mutableStateOf<Attachment?>(null) }
    var error by remember { mutableStateOf<String?>(null) }

    suspend fun load() {
        if (state !is LoadState.Loaded) state = LoadState.Loading
        state = runCatching { AttachmentRepository.fetchAttachments(tileId) }.fold(
            onSuccess = { LoadState.Loaded(it) },
            onFailure = { LoadState.Failed("Couldn't load documents.") },
        )
    }

    LaunchedEffect(tileId) { load() }

    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        uri ?: return@rememberLauncherForActivityResult
        scope.launch {
            uploading = true
            error = null
            try {
                val file = withContext(Dispatchers.IO) { readPickedFile(context, uri) }
                when {
                    file == null -> error = "Couldn't read that file."
                    file.bytes.size > MAX_BYTES -> error = "That file is over 25 MB."
                    else -> {
                        AttachmentRepository.uploadAttachment(tileId, file.bytes, file.name, file.contentType)
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        load()
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("Yona", "Attachment upload failed", e)
                error = if (BuildConfig.DEBUG) "Upload failed: ${e.message}" else "Upload failed. Please try again."
            } finally {
                uploading = false
            }
        }
    }

    fun open(attachment: Attachment) {
        if (openingId != null) return
        scope.launch {
            openingId = attachment.id
            error = null
            try {
                val uri = withContext(Dispatchers.IO) {
                    val bytes = AttachmentRepository.downloadAttachment(attachment.storagePath)
                    val dir = File(context.cacheDir, "attachments").apply { mkdirs() }
                    val file = File(dir, attachment.filename.substringAfterLast('/'))
                    file.writeBytes(bytes)
                    FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                }
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, attachment.contentType ?: "*/*")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                context.startActivity(intent)
            } catch (e: ActivityNotFoundException) {
                error = "No app can open this file type."
            } catch (e: Exception) {
                android.util.Log.e("Yona", "Attachment open failed", e)
                error = if (BuildConfig.DEBUG) "Couldn't open: ${e.message}" else "Couldn't open this document."
            } finally {
                openingId = null
            }
        }
    }

    fun remove(attachment: Attachment) {
        scope.launch {
            error = null
            try {
                AttachmentRepository.deleteAttachment(attachment)
                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                (state as? LoadState.Loaded)?.value?.let { current ->
                    state = LoadState.Loaded(current.filterNot { it.id == attachment.id })
                }
            } catch (e: Exception) {
                android.util.Log.e("Yona", "Attachment delete failed", e)
                error = if (BuildConfig.DEBUG) "Couldn't delete: ${e.message}" else "Couldn't delete this document."
            }
        }
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text("Attachments", style = MaterialTheme.typography.titleSmall)

        when (val current = state) {
            LoadState.Idle, LoadState.Loading ->
                CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)

            is LoadState.Failed -> Text(
                "Couldn't load documents.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            is LoadState.Loaded ->
                if (current.value.isEmpty()) {
                    Text(
                        "No documents yet.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                } else {
                    current.value.forEach { attachment ->
                        AttachmentRow(
                            attachment = attachment,
                            opening = openingId == attachment.id,
                            onClick = { open(attachment) },
                            onDelete = { pendingDelete = attachment },
                        )
                    }
                }
        }

        TextButton(
            onClick = { picker.launch("*/*") },
            enabled = !uploading,
        ) {
            Icon(Icons.Default.Add, contentDescription = null)
            Spacer(Modifier.width(8.dp))
            Text("Add document")
        }

        if (uploading) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                Text(
                    "Uploading…",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        error?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error,
            )
        }
    }

    pendingDelete?.let { target ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text("Delete document?") },
            text = { Text("\"${target.filename}\" will be removed. This can't be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    pendingDelete = null
                    remove(target)
                }) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) { Text("Cancel") }
            },
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun AttachmentRow(
    attachment: Attachment,
    opening: Boolean,
    onClick: () -> Unit,
    onDelete: () -> Unit,
) {
    var menuOpen by remember { mutableStateOf(false) }

    Box {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .combinedClickable(
                    enabled = !opening,
                    onClick = onClick,
                    onLongClick = { menuOpen = true },
                )
                .padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    text = attachment.filename,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                attachment.displaySize?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            if (opening) {
                CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
            } else {
                IconButton(onClick = onDelete) {
                    Icon(
                        Icons.Default.Delete,
                        contentDescription = "Delete document",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
            DropdownMenuItem(
                text = { Text("Delete") },
                onClick = {
                    menuOpen = false
                    onDelete()
                },
            )
        }
    }
}

private class PickedFile(val name: String, val contentType: String?, val bytes: ByteArray)

private fun readPickedFile(context: Context, uri: Uri): PickedFile? {
    val resolver = context.contentResolver
    val type = resolver.getType(uri)
    var name = "document"
    resolver.query(uri, null, null, null, null)?.use { cursor ->
        val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
        if (cursor.moveToFirst() && nameIndex >= 0 && !cursor.isNull(nameIndex)) {
            name = cursor.getString(nameIndex)
        }
    }
    val bytes = resolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
    return PickedFile(name, type, bytes)
}
