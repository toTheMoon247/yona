package com.yona.app.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.SubcomposeAsyncImage
import coil3.request.ImageRequest
import coil3.request.crossfade
import com.yona.app.core.Logos
import com.yona.app.core.Tile
import kotlin.math.abs

/**
 * A single Home grid cell, mirroring iOS: a soft pastel rounded-rectangle card with
 * the brand logo (Brandfetch via Coil) centered inside a circle with breathing room,
 * and the title beneath — falling back to a colored letter "logo" when none is found.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TileCard(
    tile: Tile,
    onClick: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var menuOpen by remember { mutableStateOf(false) }

    Box(modifier) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = 3.dp, shape = RoundedCornerShape(20.dp))
                .clip(RoundedCornerShape(20.dp))
                .combinedClickable(onClick = onClick, onLongClick = { menuOpen = true })
                .background(tileBackgroundColor(tile.id))
                .padding(12.dp)
                .semantics(mergeDescendants = true) {},
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            TileLogo(
                tile = tile,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 4.dp)
                    .aspectRatio(1f),
            )

            Spacer(Modifier.height(8.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                if (tile.hasNotes) {
                    Box(
                        modifier = Modifier
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(TileTitleColor)
                            .semantics { contentDescription = "has a note" },
                    )
                }
                Text(
                    text = tile.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = TileTitleColor,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }

        DropdownMenu(
            expanded = menuOpen,
            onDismissRequest = { menuOpen = false },
            shape = RoundedCornerShape(16.dp),
            containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
            shadowElevation = 8.dp,
            tonalElevation = 0.dp,
        ) {
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
                    onDelete()
                },
            )
        }
    }
}

@Composable
fun TileLogo(tile: Tile, modifier: Modifier = Modifier) {
    val brandfetchUrl = remember(tile.url) { Logos.brandfetchUrl(tile.url) }
    val faviconUrl = remember(tile.url) { Logos.faviconUrl(tile.url) }

    // Fallback chain: Brandfetch logo → site favicon → colored letter tile.
    Box(modifier.clip(CircleShape)) {
        LogoImage(brandfetchUrl, tile) {
            LogoImage(faviconUrl, tile) {
                // No website → no brand logo to load; show the full title in the circle.
                LetterTile(tile, Modifier.fillMaxSize(), usesFullTitle = !tile.hasWebsite)
            }
        }
    }
}

@Composable
private fun LogoImage(url: String?, tile: Tile, fallback: @Composable () -> Unit) {
    if (url == null) {
        fallback()
        return
    }
    SubcomposeAsyncImage(
        model = ImageRequest.Builder(LocalContext.current)
            .data(url)
            .crossfade(true)
            .build(),
        contentDescription = null, // decorative; the title text labels the tile
        modifier = Modifier.fillMaxSize(),
        contentScale = ContentScale.Fit,
        loading = { LetterTile(tile, Modifier.fillMaxSize()) },
        error = { fallback() },
    )
}

@Composable
private fun LetterTile(tile: Tile, modifier: Modifier = Modifier, usesFullTitle: Boolean = false) {
    val color = letterTileColor(tile.id)
    Box(
        modifier = modifier.background(Brush.verticalGradient(listOf(color, color.darken(0.18f)))),
        contentAlignment = Alignment.Center,
    ) {
        if (usesFullTitle && tile.title.isNotBlank()) {
            BoxWithConstraints(contentAlignment = Alignment.Center) {
                // Scale the type to the circle so the whole title fits at any size.
                val side = minOf(maxWidth, maxHeight)
                Text(
                    text = tile.title.trim(),
                    fontSize = (side.value * 0.16f).sp,
                    lineHeight = (side.value * 0.19f).sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .padding(side * 0.12f)
                        .clearAndSetSemantics {},
                )
            }
        } else {
            Text(
                text = tile.initial,
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier.clearAndSetSemantics {},
            )
        }
    }
}

// Near-black title color, readable on every pastel card in light or dark theme.
private val TileTitleColor = Color(0xFF1C1B1F)

// Soft pastel card backgrounds, mirroring the iOS DesignTokens.tileBackgrounds.
private val tileBackgrounds = listOf(
    Color(0xFFFAEBEB), // pink
    Color(0xFFE6F0FC), // blue
    Color(0xFFE8F5EB), // green
    Color(0xFFF2EBFA), // purple
    Color(0xFFFCF5E3), // amber
)

// Saturated letter-tile (placeholder logo) palette.
private val tileColors = listOf(
    Color(0xFF2563EB), // blue
    Color(0xFF16A34A), // green
    Color(0xFFF97316), // orange
    Color(0xFFEC4899), // pink
    Color(0xFF9333EA), // purple
    Color(0xFF0D9488), // teal
    Color(0xFF4F46E5), // indigo
    Color(0xFFDC2626), // red
)

private fun tileBackgroundColor(key: String): Color = tileBackgrounds[stableIndex(key, tileBackgrounds.size)]

private fun letterTileColor(key: String): Color = tileColors[stableIndex(key, tileColors.size)]

/** Deterministic djb2 index so a tile keeps the same colors across launches (mirrors iOS). */
private fun stableIndex(key: String, count: Int): Int {
    var hash = 5381
    for (byte in key.toByteArray()) {
        hash = (hash * 33) + (byte.toInt() and 0xFF)
    }
    return abs(((hash % count) + count) % count)
}

private fun Color.darken(fraction: Float): Color = Color(
    red = red * (1 - fraction),
    green = green * (1 - fraction),
    blue = blue * (1 - fraction),
    alpha = alpha,
)
