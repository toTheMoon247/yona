package com.yona.app.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.yona.app.core.Entitlement
import com.yona.app.core.LoadState
import com.yona.app.core.Tile
import com.yona.app.core.TileStore

/**
 * The signed-in app shell + lightweight navigation. Home is the root; Add and
 * Detail are shown as full-screen overlays. (Nav state resets to Home on process
 * death, which is fine — Home reloads its data.)
 */
@Composable
fun SignedInApp(modifier: Modifier = Modifier) {
    var showAdd by remember { mutableStateOf(false) }
    var showPaywall by remember { mutableStateOf(false) }
    var showBreakdown by remember { mutableStateOf(false) }
    var detailTile by remember { mutableStateOf<Tile?>(null) }
    var editTile by remember { mutableStateOf<Tile?>(null) }

    fun requestAdd() {
        val count = (TileStore.tiles as? LoadState.Loaded)?.value?.size ?: 0
        if (Entitlement.canAdd(count)) showAdd = true else showPaywall = true
    }

    val editing = editTile
    val tile = detailTile
    when {
        showPaywall -> PaywallScreen(onDismiss = { showPaywall = false })
        editing != null -> TileFormScreen(
            existing = editing,
            onDismiss = { editTile = null },
            onSaved = {
                // If editing from the detail screen, refresh & stay there; if from
                // Home (no detail open), just return to Home.
                if (detailTile != null) {
                    detailTile = (TileStore.tiles as? LoadState.Loaded)?.value
                        ?.firstOrNull { it.id == editing.id }
                }
                editTile = null
            },
        )
        showAdd -> TileFormScreen(
            existing = null,
            onDismiss = { showAdd = false },
            onSaved = { showAdd = false },
        )
        tile != null -> TileDetailScreen(
            tile = tile,
            onBack = { detailTile = null },
            onEdit = { editTile = tile },
        )
        showBreakdown -> CostBreakdownScreen(
            onBack = { showBreakdown = false },
            onTileClick = { detailTile = it },
        )
        else -> HomeScreen(
            onAddClick = { requestAdd() },
            onUpgrade = { showPaywall = true },
            onShowBreakdown = { showBreakdown = true },
            onTileClick = { detailTile = it },
            onEditTile = { editTile = it },
            modifier = modifier,
        )
    }
}
