package com.yona.app.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.yona.app.BuildConfig
import com.yona.app.core.AuthStore
import com.yona.app.core.CostPeriod
import com.yona.app.core.Entitlement
import com.yona.app.core.LoadState
import com.yona.app.core.Settings
import com.yona.app.core.Tile
import com.yona.app.core.TileSort
import com.yona.app.core.TileStore
import com.yona.app.core.formatCurrency
import java.text.Normalizer
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onAddClick: () -> Unit,
    onUpgrade: () -> Unit,
    onTileClick: (Tile) -> Unit,
    onEditTile: (Tile) -> Unit,
    modifier: Modifier = Modifier,
) {
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current
    val state = TileStore.tiles
    var query by rememberSaveable { mutableStateOf("") }
    var isRefreshing by remember { mutableStateOf(false) }
    var sort by remember { mutableStateOf(Settings.tileSort) }
    var pendingDelete by remember { mutableStateOf<Tile?>(null) }

    LaunchedEffect(Unit) { TileStore.load() }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { BrandMark() },
                actions = {
                    IconButton(onClick = { scope.launch { TileStore.load() } }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                    OverflowMenu(
                        currentSort = sort,
                        onSortSelected = {
                            sort = it
                            Settings.tileSort = it
                        },
                        onUpgrade = onUpgrade,
                        onSignOut = { scope.launch { AuthStore.signOut() } },
                    )
                },
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onAddClick) {
                Icon(Icons.Default.Add, contentDescription = "Add subscription")
            }
        },
    ) { innerPadding ->
        Box(Modifier.fillMaxSize().padding(innerPadding)) {
            when (state) {
                LoadState.Idle, LoadState.Loading -> SkeletonGrid()
                is LoadState.Failed -> ErrorState(
                    message = state.message,
                    onRetry = { scope.launch { TileStore.load() } },
                )
                is LoadState.Loaded ->
                    if (state.value.isEmpty()) {
                        EmptyState()
                    } else {
                        LoadedContent(
                            tiles = state.value,
                            query = query,
                            sort = sort,
                            onQueryChange = { query = it },
                            onTileClick = onTileClick,
                            onEditTile = onEditTile,
                            onDeleteTile = { pendingDelete = it },
                            isRefreshing = isRefreshing,
                            onRefresh = {
                                scope.launch {
                                    isRefreshing = true
                                    TileStore.load(showLoading = false)
                                    isRefreshing = false
                                }
                            },
                        )
                    }
            }
        }
    }

    pendingDelete?.let { target ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text("Delete subscription?") },
            text = { Text("\"${target.title}\" will be removed. This can't be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    pendingDelete = null
                    scope.launch {
                        TileStore.delete(target.id)
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    }
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LoadedContent(
    tiles: List<Tile>,
    query: String,
    sort: TileSort,
    onQueryChange: (String) -> Unit,
    onTileClick: (Tile) -> Unit,
    onEditTile: (Tile) -> Unit,
    onDeleteTile: (Tile) -> Unit,
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
) {
    val filtered = remember(tiles, query) { tiles.filter { it.matches(query) } }
    val sorted = remember(filtered, sort) { sort.sorted(filtered) }

    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = onRefresh,
        modifier = Modifier.fillMaxSize(),
    ) {
        Column(Modifier.fillMaxSize()) {
            SpendHeader(tiles)
            SearchField(query = query, onQueryChange = onQueryChange)
            if (sorted.isEmpty()) {
                NoResults(query)
            } else {
                TileGrid(sorted, onTileClick, onEditTile, onDeleteTile)
            }
        }
    }
}

/**
 * Spend hero: the exact total per year (monthly × 12 + yearly), with the monthly /
 * yearly split and a count per bucket. Computed over all subscriptions. Mirrors iOS.
 */
@Composable
private fun SpendHeader(tiles: List<Tile>) {
    val monthlySubs = tiles.filter { it.costPeriod == CostPeriod.MONTHLY && it.costAmount != null }
    val yearlySubs = tiles.filter { it.costPeriod == CostPeriod.YEARLY && it.costAmount != null }
    val monthlyTotal = monthlySubs.sumOf { it.costAmount ?: 0.0 }
    val yearlyTotal = yearlySubs.sumOf { it.costAmount ?: 0.0 }
    val annualTotal = monthlyTotal * 12 + yearlyTotal
    if (annualTotal <= 0.0) return

    val onSurface = MaterialTheme.colorScheme.onSurface
    val onSurfaceVariant = MaterialTheme.colorScheme.onSurfaceVariant

    val buckets = buildList {
        if (monthlyTotal > 0) add("${formatCurrency(monthlyTotal)}/mo · ${subCount(monthlySubs.size)}")
        if (yearlyTotal > 0) add("${formatCurrency(yearlyTotal)}/yr · ${subCount(yearlySubs.size)}")
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 16.dp, end = 16.dp, top = 8.dp),
    ) {
        Text(
            text = "You pay",
            style = MaterialTheme.typography.bodyMedium,
            color = onSurfaceVariant,
        )
        Text(
            text = buildAnnotatedString {
                withStyle(SpanStyle(fontSize = 30.sp, fontWeight = FontWeight.Bold, color = onSurface)) {
                    append(formatCurrency(annualTotal))
                }
                withStyle(SpanStyle(fontSize = 18.sp, color = onSurfaceVariant)) {
                    append(" a year")
                }
            },
        )
        Text(
            text = buckets.joinToString("   ·   "),
            style = MaterialTheme.typography.bodyMedium,
            color = onSurfaceVariant,
        )
    }
}

private fun subCount(count: Int): String = "$count sub${if (count == 1) "" else "s"}"

/** The Home brand mark: a small 2×2 grid glyph + the full app name (mirrors iOS). */
@Composable
private fun BrandMark() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        BrandGridIcon()
        Text(
            text = "Yona: Subscription Tracker",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun BrandGridIcon() {
    val color = MaterialTheme.colorScheme.primary
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        repeat(2) {
            Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                repeat(2) {
                    Box(
                        Modifier
                            .size(7.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(color),
                    )
                }
            }
        }
    }
}

@Composable
private fun SearchField(query: String, onQueryChange: (String) -> Unit) {
    TextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        placeholder = { Text("Search") },
        singleLine = true,
        shape = RoundedCornerShape(28.dp),
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Default.Clear, contentDescription = "Clear search")
                }
            }
        },
        colors = TextFieldDefaults.colors(
            focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
            unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant,
            focusedIndicatorColor = Color.Transparent,
            unfocusedIndicatorColor = Color.Transparent,
            disabledIndicatorColor = Color.Transparent,
        ),
    )
}

@Composable
private fun NoResults(query: String) {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("No results", style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(8.dp))
        Text(
            text = "Nothing matches “$query”.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

/** Case- and diacritic-insensitive match on title or URL (mirrors iOS search). */
private fun Tile.matches(query: String): Boolean {
    val needle = fold(query.trim())
    if (needle.isEmpty()) return true
    return fold(title).contains(needle) || fold(url).contains(needle)
}

private fun fold(text: String): String =
    Normalizer.normalize(text, Normalizer.Form.NFD)
        .replace(Regex("\\p{Mn}+"), "")
        .lowercase()

@Composable
private fun TileGrid(
    tiles: List<Tile>,
    onTileClick: (Tile) -> Unit,
    onEditTile: (Tile) -> Unit,
    onDeleteTile: (Tile) -> Unit,
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        items(tiles, key = { it.id }) { tile ->
            TileCard(
                tile = tile,
                onClick = { onTileClick(tile) },
                onEdit = { onEditTile(tile) },
                onDelete = { onDeleteTile(tile) },
                modifier = Modifier.animateItem(),
            )
        }
    }
}

@Composable
private fun SkeletonGrid() {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        items(6) { TileCardSkeleton() }
    }
}

@Composable
private fun TileCardSkeleton() {
    val transition = rememberInfiniteTransition(label = "skeleton")
    val alpha by transition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "alpha",
    )
    val placeholder = MaterialTheme.colorScheme.onSurface.copy(alpha = alpha * 0.2f)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))
            .padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 4.dp)
                .aspectRatio(1f)
                .clip(CircleShape)
                .background(placeholder),
        )
        Spacer(Modifier.height(8.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth(0.6f)
                .height(14.dp)
                .clip(RoundedCornerShape(7.dp))
                .background(placeholder),
        )
        Spacer(Modifier.height(4.dp))
    }
}

@Composable
private fun EmptyState() {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("No subscriptions yet", style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(8.dp))
        Text(
            text = "Your subscriptions will appear here.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun ErrorState(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(16.dp))
        TextButton(onClick = onRetry) { Text("Retry") }
    }
}

@Composable
private fun OverflowMenu(
    currentSort: TileSort,
    onSortSelected: (TileSort) -> Unit,
    onUpgrade: () -> Unit,
    onSignOut: () -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    IconButton(onClick = { expanded = true }) {
        Icon(Icons.Default.MoreVert, contentDescription = "More")
    }
    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
        Text(
            text = "Sort by",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        )
        TileSort.entries.forEach { option ->
            DropdownMenuItem(
                text = { Text(option.label) },
                onClick = {
                    expanded = false
                    onSortSelected(option)
                },
                leadingIcon = {
                    if (option == currentSort) {
                        Icon(Icons.Default.Check, contentDescription = null)
                    } else {
                        Spacer(Modifier.size(24.dp))
                    }
                },
            )
        }
        HorizontalDivider()
        if (!Entitlement.isPremium) {
            DropdownMenuItem(
                text = { Text("Upgrade to Premium") },
                onClick = {
                    expanded = false
                    onUpgrade()
                },
            )
        }
        if (BuildConfig.DEBUG) {
            DropdownMenuItem(
                text = { Text("Dev: ${if (Entitlement.isPremium) "Disable" else "Enable"} Premium") },
                onClick = {
                    expanded = false
                    Entitlement.setDevPremium(!Entitlement.isPremium)
                },
            )
        }
        DropdownMenuItem(
            text = { Text("Sign out") },
            onClick = {
                expanded = false
                onSignOut()
            },
        )
    }
}
