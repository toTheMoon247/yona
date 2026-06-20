package com.yona.app.ui

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yona.app.core.BillingSource
import com.yona.app.core.Logos
import com.yona.app.core.Tile
import com.yona.app.core.TileStore
import com.yona.app.core.UrlHelpers
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TileDetailScreen(tile: Tile, onBack: () -> Unit, onEdit: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current

    var menuOpen by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var deleting by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(tile.title, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { menuOpen = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "More")
                    }
                    DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                        DropdownMenuItem(
                            text = { Text("Edit") },
                            onClick = {
                                menuOpen = false
                                onEdit()
                            },
                        )
                        DropdownMenuItem(
                            text = { Text("Delete") },
                            onClick = {
                                menuOpen = false
                                confirmDelete = true
                            },
                        )
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(20.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Spacer(Modifier.height(8.dp))

            Box(
                modifier = Modifier
                    .size(96.dp)
                    .clip(CircleShape)
                    .border(1.dp, MaterialTheme.colorScheme.outlineVariant, CircleShape),
            ) {
                TileLogo(tile, Modifier.fillMaxSize())
            }

            Text(
                text = tile.title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
            if (tile.hasWebsite) {
                Text(
                    text = Logos.domain(tile.url) ?: tile.url,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            tile.formattedCost?.let { cost ->
                Text(
                    text = cost,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            tile.renewalSummary?.let { renews ->
                Text(
                    text = "Renews $renews",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            BillingSource.fromRaw(tile.billingSource)?.let { source ->
                val method = tile.paymentMethod?.takeIf { it.isNotBlank() }
                val text = if (source.usesPaymentMethod && method != null) {
                    "Billed via ${source.label} · $method"
                } else {
                    "Billed via ${source.label}"
                }
                Text(
                    text = text,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            if (tile.hasWebsite) {
                Spacer(Modifier.height(4.dp))

                Button(
                    onClick = { openUrl(context, tile.url) },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Open Website")
                }
            }

            if (tile.hasNotes) {
                NotesCard(tile.notes.orEmpty())
            }

            AttachmentsView(tileId = tile.id, modifier = Modifier.fillMaxWidth())
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { if (!deleting) confirmDelete = false },
            title = { Text("Delete subscription?") },
            text = { Text("\"${tile.title}\" will be removed. This can't be undone.") },
            confirmButton = {
                TextButton(
                    enabled = !deleting,
                    onClick = {
                        scope.launch {
                            deleting = true
                            TileStore.delete(tile.id)
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            confirmDelete = false
                            deleting = false
                            onBack()
                        }
                    },
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(enabled = !deleting, onClick = { confirmDelete = false }) {
                    Text("Cancel")
                }
            },
        )
    }
}

@Composable
private fun NotesCard(notes: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(16.dp),
    ) {
        Text("Notes", style = MaterialTheme.typography.titleSmall)
        Spacer(Modifier.height(6.dp))
        Text(
            text = notes,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun openUrl(context: Context, raw: String) {
    val uri = Uri.parse(UrlHelpers.normalized(raw))
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, uri)) }
}
