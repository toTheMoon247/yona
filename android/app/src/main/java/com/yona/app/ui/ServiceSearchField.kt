package com.yona.app.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.yona.app.core.BrandResult
import com.yona.app.core.ServiceSearch
import kotlinx.coroutines.delay

/**
 * Search a brand by name (debounced Brandfetch Brand Search) and pick a result to
 * auto-fill the tile's name + domain. Mirrors the iOS ServiceSearchField.
 */
@Composable
fun ServiceSearchField(
    onSelect: (name: String, domain: String) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    var query by rememberSaveable { mutableStateOf("") }
    var results by remember { mutableStateOf<List<BrandResult>>(emptyList()) }
    var searching by remember { mutableStateOf(false) }

    // Debounced search: a new keystroke cancels the pending delay + request.
    LaunchedEffect(query) {
        val trimmed = query.trim()
        if (trimmed.length < 2) {
            results = emptyList()
            searching = false
            return@LaunchedEffect
        }
        delay(300)
        searching = true
        results = ServiceSearch.search(trimmed)
        searching = false
    }

    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            label = { Text("Find a service") },
            placeholder = { Text("e.g. Netflix") },
            singleLine = true,
            enabled = enabled,
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
            modifier = Modifier.fillMaxWidth(),
        )

        if (searching) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                Text(
                    "Searching…",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        results.forEach { result ->
            BrandRow(result) {
                onSelect(result.displayName, result.domain)
                query = ""
                results = emptyList()
            }
        }

        if (!searching && results.isEmpty() && query.trim().length >= 2) {
            Text(
                "No matches — fill in the details below.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun BrandRow(result: BrandResult, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        AsyncImage(
            model = result.icon,
            contentDescription = null,
            modifier = Modifier
                .size(28.dp)
                .clip(RoundedCornerShape(6.dp)),
            contentScale = ContentScale.Fit,
        )
        Column {
            Text(result.displayName, style = MaterialTheme.typography.bodyMedium)
            Text(
                result.domain,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
