package com.yona.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yona.app.core.AuthStore
import kotlinx.coroutines.launch

/**
 * Placeholder home shown when signed in. Real tile grid arrives in Phase A2.
 */
@Composable
fun HomePlaceholderScreen(modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    val email = remember { AuthStore.currentUserEmail }

    Surface(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = "You're signed in 🎉",
                style = MaterialTheme.typography.titleLarge,
            )
            if (email != null) {
                Spacer(Modifier.height(8.dp))
                Text(
                    text = email,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }

            Spacer(Modifier.height(32.dp))

            OutlinedButton(onClick = { scope.launch { AuthStore.signOut() } }) {
                Text("Sign out")
            }
        }
    }
}
