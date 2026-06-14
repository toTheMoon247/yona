package com.yona.app.core

/**
 * The four explicit states every async screen renders, mirroring the iOS
 * `LoadState<T>` enum: idle, loading, loaded(value), or failed(message).
 */
sealed interface LoadState<out T> {
    data object Idle : LoadState<Nothing>
    data object Loading : LoadState<Nothing>
    data class Loaded<T>(val value: T) : LoadState<T>
    data class Failed(val message: String) : LoadState<Nothing>
}
