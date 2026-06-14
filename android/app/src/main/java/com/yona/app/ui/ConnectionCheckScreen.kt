package com.yona.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yona.app.core.AppConfig
import com.yona.app.core.LoadState
import com.yona.app.core.Supabase

/**
 * Phase A0 placeholder: confirms the app is wired to Supabase by pinging the
 * backend on launch and rendering all four [LoadState] states.
 */
@Composable
fun ConnectionCheckScreen(modifier: Modifier = Modifier) {
    var state by remember { mutableStateOf<LoadState<Unit>>(LoadState.Idle) }

    LaunchedEffect(Unit) {
        state = LoadState.Loading
        state = Supabase.checkConnection().fold(
            onSuccess = { LoadState.Loaded(Unit) },
            onFailure = { LoadState.Failed(it.message ?: "Unknown error") },
        )
    }

    Surface(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text("Yona for Android", style = MaterialTheme.typography.headlineMedium)
            Spacer(Modifier.height(8.dp))
            Text(
                text = if (AppConfig.isConfigured) AppConfig.supabaseHost else "Not configured",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Spacer(Modifier.height(40.dp))

            when (val current = state) {
                LoadState.Idle, LoadState.Loading -> {
                    CircularProgressIndicator()
                    Spacer(Modifier.height(16.dp))
                    Text("Connecting to Supabase…")
                }

                is LoadState.Loaded -> {
                    Text(
                        text = "✓ Connected to Supabase",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }

                is LoadState.Failed -> {
                    Text(
                        text = "✕ Connection failed",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.error,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = current.message,
                        style = MaterialTheme.typography.bodySmall,
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}
