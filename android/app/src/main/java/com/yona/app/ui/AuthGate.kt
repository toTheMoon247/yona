package com.yona.app.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.yona.app.core.AuthStore
import io.github.jan.supabase.auth.status.SessionStatus

/**
 * Routes between sign-in and the signed-in app based on the Supabase session status.
 *
 * Supabase re-emits `Initializing` briefly every time the app returns to the
 * foreground (e.g. after the file picker). We must keep the signed-in shell mounted
 * across that transient state — otherwise the whole UI is torn down and recreated,
 * losing navigation and cancelling in-flight work like an upload. So we compute a
 * single `showApp` flag and render `SignedInApp` from one call site, which stays
 * stable across the Authenticated → Initializing → Authenticated flicker.
 * Mirrors the iOS ContentView.
 */
@Composable
fun AuthGate(modifier: Modifier = Modifier) {
    val status by AuthStore.sessionStatus.collectAsState()
    var hasSession by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(status) {
        when (status) {
            is SessionStatus.Authenticated -> hasSession = true
            is SessionStatus.NotAuthenticated -> hasSession = false
            else -> Unit // Initializing / RefreshFailure: keep the current value
        }
    }

    val showApp = status is SessionStatus.Authenticated ||
        (status is SessionStatus.Initializing && hasSession)
    val signedOut = status is SessionStatus.NotAuthenticated ||
        status is SessionStatus.RefreshFailure

    when {
        showApp -> SignedInApp(modifier)
        signedOut -> SignInScreen(modifier)
        else -> LoadingScreen(modifier)
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
