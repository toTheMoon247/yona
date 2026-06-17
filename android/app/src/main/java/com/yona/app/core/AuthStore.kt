package com.yona.app.core

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.flow.StateFlow

/**
 * Owns auth/session state for the UI. Google sign-in runs through Supabase's
 * external-browser OAuth flow (redirect `yona://auth-callback`, completed via the
 * deep link in MainActivity); Apple sign-in is a stub until the Apple Developer
 * Program is enrolled. Mirrors the iOS AuthStore.
 */
object AuthStore {
    private val auth get() = Supabase.client.auth

    /** Drives the AuthGate: Initializing / Authenticated / NotAuthenticated / RefreshFailure. */
    val sessionStatus: StateFlow<SessionStatus> get() = auth.sessionStatus

    var isAuthenticating by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    /** Email of the signed-in user, if any. */
    val currentUserEmail: String? get() = auth.currentUserOrNull()?.email

    suspend fun signInWithGoogle() {
        isAuthenticating = true
        errorMessage = null
        try {
            // Opens a Custom Tab; the session is completed asynchronously via the
            // deep-link redirect, which flips sessionStatus to Authenticated.
            auth.signInWith(Google) {
                scopes.add("email")
                scopes.add("profile")
            }
        } catch (e: Exception) {
            errorMessage = e.message ?: "Sign-in failed. Please try again."
        } finally {
            isAuthenticating = false
        }
    }

    suspend fun signOut() {
        errorMessage = null
        try {
            TileCache.clear() // while still signed in (cache file is keyed by user id)
            auth.signOut()
            TileStore.reset()
        } catch (e: Exception) {
            errorMessage = "Sign-out failed. Please try again."
        }
    }
}
