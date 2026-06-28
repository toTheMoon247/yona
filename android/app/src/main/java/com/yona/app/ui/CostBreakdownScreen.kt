package com.yona.app.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.yona.app.core.LoadState
import com.yona.app.core.Settings
import com.yona.app.core.Tile
import com.yona.app.core.TileStore
import com.yona.app.core.formatCurrency
import kotlin.math.roundToInt

/**
 * Tap the spend total on Home → a per-subscription cost breakdown: every paid
 * subscription, normalized to the chosen unit, sorted high → low, each with its
 * share of the total. Mirrors the iOS CostBreakdownView (roadmap #8).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CostBreakdownScreen(onBack: () -> Unit, onTileClick: (Tile) -> Unit) {
    val tiles = (TileStore.tiles as? LoadState.Loaded)?.value.orEmpty()
        .filter { it.annualizedCost != null }
    val totalAnnual = tiles.sumOf { it.annualizedCost ?: 0.0 }
    val sorted = tiles.sortedByDescending { it.annualizedCost ?: 0.0 }

    var showMonthly by remember { mutableStateOf(Settings.spendShowsMonthly) }
    val displayTotal = if (showMonthly) totalAnnual / 12 else totalAnnual

    val onSurface = MaterialTheme.colorScheme.onSurface
    val onSurfaceVariant = MaterialTheme.colorScheme.onSurfaceVariant

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Spending") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(
                        text = buildAnnotatedString {
                            withStyle(SpanStyle(fontSize = 16.sp, color = onSurfaceVariant)) {
                                append("You pay ")
                            }
                            withStyle(SpanStyle(fontSize = 30.sp, fontWeight = FontWeight.Bold, color = onSurface)) {
                                append(formatCurrency(displayTotal))
                            }
                            withStyle(SpanStyle(fontSize = 18.sp, color = onSurfaceVariant)) {
                                append(if (showMonthly) " a month" else " a year")
                            }
                        },
                    )
                    SingleChoiceSegmentedButtonRow {
                        SegmentedButton(
                            selected = showMonthly,
                            onClick = { showMonthly = true; Settings.spendShowsMonthly = true },
                            shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2),
                        ) { Text("Monthly") }
                        SegmentedButton(
                            selected = !showMonthly,
                            onClick = { showMonthly = false; Settings.spendShowsMonthly = false },
                            shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2),
                        ) { Text("Yearly") }
                    }
                }
                HorizontalDivider()
            }

            items(sorted, key = { it.id }) { tile ->
                BreakdownRow(
                    tile = tile,
                    totalAnnual = totalAnnual,
                    showMonthly = showMonthly,
                    onClick = { onTileClick(tile) },
                )
                HorizontalDivider()
            }
        }
    }
}

@Composable
private fun BreakdownRow(tile: Tile, totalAnnual: Double, showMonthly: Boolean, onClick: () -> Unit) {
    val perItem = if (showMonthly) tile.monthlyCost ?: 0.0 else tile.annualizedCost ?: 0.0
    val share = if (totalAnnual > 0) (tile.annualizedCost ?: 0.0) / totalAnnual else 0.0

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape),
        ) {
            TileLogo(tile, Modifier.fillMaxSize())
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(tile.title, maxLines = 1, overflow = TextOverflow.Ellipsis)
            tile.formattedCost?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = formatCurrency(perItem) + if (showMonthly) "/mo" else "/yr",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
            )
            Text(
                text = "${(share * 100).roundToInt()}%",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
