package com.yona.app.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier

/**
 * The signed-in app shell + lightweight navigation. Home is the root; the Add
 * screen is shown as a full-screen overlay. Detail/edit routes are added in later
 * A2 slices.
 */
@Composable
fun SignedInApp(modifier: Modifier = Modifier) {
    var showAdd by rememberSaveable { mutableStateOf(false) }

    if (showAdd) {
        AddTileScreen(
            onDismiss = { showAdd = false },
            onSaved = { showAdd = false },
        )
    } else {
        HomeScreen(onAddClick = { showAdd = true }, modifier = modifier)
    }
}
