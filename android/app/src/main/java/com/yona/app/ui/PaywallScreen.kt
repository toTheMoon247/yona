package com.yona.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yona.app.BuildConfig
import com.yona.app.core.Entitlement

/**
 * Shown when a free user tries to add a subscription past the free limit (or taps
 * Upgrade). Prices/plans are placeholders until Play Billing / RevenueCat is wired;
 * the purchase action is a DEBUG dev-unlock for now. Mirrors the iOS PaywallView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallScreen(onDismiss: () -> Unit) {
    // false = yearly (default), true = lifetime
    var lifetime by rememberSaveable { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
                actions = {
                    TextButton(onClick = onDismiss) { Text("Not now") }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Header()
            Benefits()

            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                PlanCard(
                    selected = !lifetime,
                    title = "Yearly",
                    price = "$1.99 / year",
                    note = "Billed annually",
                    onClick = { lifetime = false },
                )
                PlanCard(
                    selected = lifetime,
                    title = "Lifetime",
                    price = "$4.99 once",
                    note = "Pay once, yours forever",
                    onClick = { lifetime = true },
                )
            }

            Button(
                onClick = { purchase(onDismiss) },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(if (lifetime) "Unlock Lifetime" else "Start Yearly")
            }

            TextButton(onClick = { /* TODO: restore via Play Billing / RevenueCat */ }) {
                Text("Restore Purchases", style = MaterialTheme.typography.bodySmall)
            }

            Text(
                text = "Yona is free for up to ${Entitlement.FREE_TILE_LIMIT} subscriptions. " +
                    "Premium adds unlimited subscriptions. Cancel anytime.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }
    }
}

private fun purchase(onDismiss: () -> Unit) {
    if (BuildConfig.DEBUG) {
        // Dev-unlock until real billing is connected.
        Entitlement.setDevPremium(true)
        onDismiss()
    }
    // else: TODO real purchase via Play Billing / RevenueCat.
}

@Composable
private fun Header() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(top = 16.dp),
    ) {
        // Large 2×2 brand glyph.
        val color = MaterialTheme.colorScheme.primary
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            repeat(2) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    repeat(2) {
                        Box(
                            Modifier
                                .size(22.dp)
                                .clip(RoundedCornerShape(6.dp))
                                .background(color),
                        )
                    }
                }
            }
        }
        Spacer(Modifier.size(4.dp))
        Text(
            text = "Yona Premium",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
        )
        Text(
            text = "Track unlimited subscriptions",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun Benefits() {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        BenefitRow("Unlimited subscriptions (free includes ${Entitlement.FREE_TILE_LIMIT})")
        BenefitRow("Everything in the free version — logos, costs, renewals, documents")
    }
}

@Composable
private fun BenefitRow(text: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            Icons.Filled.Check,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(24.dp),
        )
        Text(text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun PlanCard(
    selected: Boolean,
    title: String,
    price: String,
    note: String,
    onClick: () -> Unit,
) {
    val accent = MaterialTheme.colorScheme.primary
    val background = if (selected) accent.copy(alpha = 0.12f) else MaterialTheme.colorScheme.surfaceVariant
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(background)
            .border(
                width = 2.dp,
                color = if (selected) accent else Color.Transparent,
                shape = RoundedCornerShape(12.dp),
            )
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Text(
                note,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Spacer(Modifier.width(12.dp))
        Text(price, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
    }
}
