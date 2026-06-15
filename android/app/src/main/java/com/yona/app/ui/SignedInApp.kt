package com.yona.app.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.yona.app.core.Tile

/**
 * The signed-in app shell + lightweight navigation. Home is the root; Add and
 * Detail are shown as full-screen overlays. (Nav state resets to Home on process
 * death, which is fine — Home reloads its data.)
 */
@Composable
fun SignedInApp(modifier: Modifier = Modifier) {
    var showAdd by remember { mutableStateOf(false) }
    var detailTile by remember { mutableStateOf<Tile?>(null) }

    val tile = detailTile
    when {
        showAdd -> AddTileScreen(
            onDismiss = { showAdd = false },
            onSaved = { showAdd = false },
        )
        tile != null -> TileDetailScreen(
            tile = tile,
            onBack = { detailTile = null },
        )
        else -> HomeScreen(
            onAddClick = { showAdd = true },
            onTileClick = { detailTile = it },
            modifier = modifier,
        )
    }
}
