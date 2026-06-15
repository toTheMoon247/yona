package com.yona.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yona.app.core.Tile
import kotlin.math.abs

/**
 * A single Home grid cell: a placeholder letter "logo" filling the cell, with the
 * title beneath. Real brand logos replace the circle in Phase A3.
 */
@Composable
fun TileCard(tile: Tile, modifier: Modifier = Modifier) {
    val color = letterTileColor(tile.id)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Top,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(CircleShape)
                .background(Brush.verticalGradient(listOf(color, color.darken(0.18f)))),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = tile.initial,
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = Color.White,
            )
        }

        Spacer(Modifier.height(8.dp))

        Text(
            text = tile.title,
            style = MaterialTheme.typography.bodyMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// Letter-tile palette + stable color, mirroring the iOS DesignTokens (djb2 hash so
// a tile keeps the same color across launches).
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

private fun letterTileColor(key: String): Color {
    var hash = 5381
    for (byte in key.toByteArray()) {
        hash = (hash * 33) + (byte.toInt() and 0xFF)
    }
    val index = ((hash % tileColors.size) + tileColors.size) % tileColors.size
    return tileColors[abs(index)]
}

private fun Color.darken(fraction: Float): Color = Color(
    red = red * (1 - fraction),
    green = green * (1 - fraction),
    blue = blue * (1 - fraction),
    alpha = alpha,
)
