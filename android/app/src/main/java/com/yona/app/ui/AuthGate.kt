package com.yona.app.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.yona.app.core.AuthStore
import io.github.jan.supabase.auth.status.SessionStatus

/**
 * Routes between sign-in and the (placeholder) home based on the Supabase session
 * status. On cold launch the status starts Initializing while the stored session
 * loads, so the user stays signed in across launches. Mirrors the iOS ContentView.
 */
@Composable
fun AuthGate(modifier: Modifier = Modifier) {
    val status by AuthStore.sessionStatus.collectAsState()

    when (status) {
        is SessionStatus.Initializing -> LoadingScreen(modifier)
        is SessionStatus.Authenticated -> SignedInApp(modifier)
        is SessionStatus.NotAuthenticated,
        is SessionStatus.RefreshFailure -> SignInScreen(modifier)
    }
}

@Composable
private fun LoadingScreen(modifier: Modifier = Modifier) {
    Surface(modifier = modifier.fillMaxSize()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
    }
}
