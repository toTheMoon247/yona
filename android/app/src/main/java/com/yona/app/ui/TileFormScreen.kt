package com.yona.app.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AssistChip
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.yona.app.core.BillingSource
import com.yona.app.core.CostPeriod
import com.yona.app.core.RenewalRepeat
import com.yona.app.core.Tile
import com.yona.app.core.TileDraft
import com.yona.app.core.TileStore
import com.yona.app.core.UrlHelpers
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Create (existing == null) or edit (existing != null) a tile. Reuses one form for
 * both, mirroring the iOS shared form — inset "grouped cards" on a tonal page.
 */

/** Prefill the cost field without a trailing ".0" for whole amounts. */
private fun formatAmount(amount: Double): String =
    if (amount % 1.0 == 0.0) amount.toLong().toString() else amount.toString()

private val formDateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.getDefault())

private fun displayDate(iso: String): String =
    runCatching { LocalDate.parse(iso).format(formDateFormatter) }.getOrDefault(iso)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun TileFormScreen(existing: Tile?, onDismiss: () -> Unit, onSaved: () -> Unit) {
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current
    val editing = existing != null
    val currencySymbol = remember { NumberFormat.getCurrencyInstance().currency?.symbol ?: "$" }

    var title by rememberSaveable { mutableStateOf(existing?.title ?: "") }
    var url by rememberSaveable { mutableStateOf(existing?.url ?: "") }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    var costText by rememberSaveable { mutableStateOf(existing?.costAmount?.let { formatAmount(it) } ?: "") }
    var period by rememberSaveable { mutableStateOf(existing?.costPeriod ?: CostPeriod.MONTHLY) }
    var renewalDate by rememberSaveable { mutableStateOf(existing?.renewalDate) }
    var renewalRepeat by rememberSaveable { mutableStateOf(existing?.renewalRepeat) }
    var billingRaw by rememberSaveable { mutableStateOf(existing?.billingSource) }
    var paymentMethod by rememberSaveable { mutableStateOf(existing?.paymentMethod ?: "") }
    var showDatePicker by remember { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    val canSave = title.isNotBlank() && !saving

    BackHandler(enabled = !saving) { onDismiss() }

    fun pickRenewal(date: LocalDate) {
        renewalDate = date.toString()
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
    }

    fun save() {
        scope.launch {
            saving = true
            error = null
            val amount = costText.trim().toDoubleOrNull()?.takeIf { it > 0 }
            val source = BillingSource.fromRaw(billingRaw)
            val draft = TileDraft(
                title = title.trim(),
                url = UrlHelpers.normalized(url),
                notes = notes.trim().ifBlank { null },
                costAmount = amount,
                costPeriod = if (amount != null) period else null,
                renewalDate = renewalDate,
                renewalRepeat = if (renewalDate != null) renewalRepeat else null,
                billingSource = billingRaw,
                // Only store a payment method for sources that use one; clear it otherwise.
                paymentMethod = if (source?.usesPaymentMethod == true) paymentMethod.trim().ifBlank { null } else null,
            )
            val result = if (existing != null) {
                TileStore.update(existing.id, draft)
            } else {
                TileStore.create(draft)
            }
            result.fold(
                onSuccess = {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onSaved()
                },
                onFailure = {
                    error = it.message ?: "Couldn't save. Please try again."
                    saving = false
                },
            )
        }
    }

    val page = MaterialTheme.colorScheme.surfaceContainerLow

    Scaffold(
        containerColor = page,
        topBar = {
            TopAppBar(
                title = { Text(if (editing) "Edit subscription" else "Add subscription") },
                navigationIcon = {
                    IconButton(onClick = onDismiss, enabled = !saving) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    TextButton(onClick = { save() }, enabled = canSave) {
                        Text("Save")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = page),
            )
        },
    ) { innerPadding ->
        val billingSource = BillingSource.fromRaw(billingRaw)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            if (existing == null) {
                ServiceSearchField(
                    onSelect = { name, domain ->
                        title = name
                        url = domain
                    },
                    enabled = !saving,
                )
            }

            // Identity — Title + Website grouped, like the iOS top card.
            FormSection {
                CardTextField(title, { title = it }, "Title", !saving)
                InsetDivider()
                CardTextField(
                    url, { url = it }, "Website (optional)", !saving,
                    keyboardType = KeyboardType.Uri,
                )
            }

            FormSection(label = "Notes (optional)") {
                CardTextField(
                    notes, { notes = it }, "Notes", !saving,
                    singleLine = false, minLines = 3,
                )
            }

            FormSection(label = "Cost (optional)") {
                CardTextField(
                    costText, { costText = it }, "0.00", !saving,
                    keyboardType = KeyboardType.Decimal, prefix = currencySymbol,
                )
                if (costText.isNotBlank()) {
                    InsetDivider()
                    FlowRow(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        CostPeriod.all.forEach { option ->
                            FilterChip(
                                selected = period == option,
                                onClick = { period = option },
                                label = { Text(CostPeriod.label(option)) },
                                enabled = !saving,
                            )
                        }
                    }
                }
            }

            FormSection(
                label = "How it's paid (optional)",
                footer = if (billingSource?.usesPaymentMethod == true) {
                    "Card type + last 4 only — never full card numbers."
                } else {
                    "Where this subscription is billed, so you know where to cancel or manage it."
                },
            ) {
                Column(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(
                        text = "Billed through",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FilterChip(
                            selected = billingRaw == null,
                            onClick = { billingRaw = null },
                            label = { Text("Not set") },
                            enabled = !saving,
                        )
                        BillingSource.entries.forEach { source ->
                            FilterChip(
                                selected = billingRaw == source.raw,
                                onClick = { billingRaw = source.raw },
                                label = { Text(source.label) },
                                enabled = !saving,
                            )
                        }
                    }
                }
                if (billingSource?.usesPaymentMethod == true) {
                    InsetDivider()
                    CardTextField(
                        paymentMethod, { paymentMethod = it },
                        "Payment method — e.g. Visa ••1234", !saving,
                    )
                }
            }

            FormSection(label = "Renewal date (optional)") {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        AssistChip(onClick = { pickRenewal(LocalDate.now()) }, label = { Text("Today") })
                        AssistChip(
                            onClick = { pickRenewal(LocalDate.now().plusMonths(1)) },
                            label = { Text("+1 month") },
                        )
                        AssistChip(
                            onClick = { pickRenewal(LocalDate.now().plusYears(1)) },
                            label = { Text("+1 year") },
                        )
                    }

                    val currentRenewal = renewalDate
                    if (currentRenewal != null) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "Renews ${displayDate(currentRenewal)}",
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.weight(1f),
                            )
                            TextButton(onClick = { showDatePicker = true }, enabled = !saving) {
                                Text("Change")
                            }
                            TextButton(
                                onClick = { renewalDate = null; renewalRepeat = null },
                                enabled = !saving,
                            ) { Text("Clear") }
                        }
                        FlowRow(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            FilterChip(
                                selected = renewalRepeat == null,
                                onClick = { renewalRepeat = null },
                                label = { Text("Never") },
                                enabled = !saving,
                            )
                            RenewalRepeat.all.forEach { option ->
                                FilterChip(
                                    selected = renewalRepeat == option,
                                    onClick = { renewalRepeat = option },
                                    label = { Text(RenewalRepeat.label(option)) },
                                    enabled = !saving,
                                )
                            }
                        }
                    } else {
                        TextButton(onClick = { showDatePicker = true }, enabled = !saving) {
                            Text("Pick a date…")
                        }
                    }
                }
            }

            error?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(start = 8.dp),
                )
            }

            if (saving) {
                CircularProgressIndicator()
            }
        }
    }

    if (showDatePicker) {
        val initialMillis = renewalDate
            ?.let { runCatching { LocalDate.parse(it).toEpochDay() * 86_400_000L }.getOrNull() }
        val dateState = rememberDatePickerState(initialSelectedDateMillis = initialMillis)
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    dateState.selectedDateMillis?.let { millis ->
                        renewalDate = Instant.ofEpochMilli(millis)
                            .atZone(ZoneOffset.UTC).toLocalDate().toString()
                    }
                    showDatePicker = false
                }) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) { Text("Cancel") }
            },
        ) {
            DatePicker(state = dateState)
        }
    }
}

/** A labelled inset "card" section on the tonal page (iOS inset-grouped look). */
@Composable
private fun FormSection(
    label: String? = null,
    footer: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        if (label != null) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 8.dp),
            )
        }
        Surface(
            shape = RoundedCornerShape(16.dp),
            color = MaterialTheme.colorScheme.surfaceContainerLowest,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(content = content)
        }
        if (footer != null) {
            Text(
                text = footer,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 8.dp),
            )
        }
    }
}

/** A borderless text field that sits flush inside a [FormSection] card. */
@Composable
private fun CardTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    enabled: Boolean,
    keyboardType: KeyboardType = KeyboardType.Text,
    singleLine: Boolean = true,
    minLines: Int = 1,
    prefix: String? = null,
) {
    TextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(placeholder, color = MaterialTheme.colorScheme.onSurfaceVariant) },
        prefix = prefix?.let { { Text("$it ", color = MaterialTheme.colorScheme.onSurfaceVariant) } },
        enabled = enabled,
        singleLine = singleLine,
        minLines = minLines,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
        colors = TextFieldDefaults.colors(
            focusedContainerColor = Color.Transparent,
            unfocusedContainerColor = Color.Transparent,
            disabledContainerColor = Color.Transparent,
            focusedIndicatorColor = Color.Transparent,
            unfocusedIndicatorColor = Color.Transparent,
            disabledIndicatorColor = Color.Transparent,
        ),
        modifier = Modifier.fillMaxWidth(),
    )
}

/** A hairline divider inset from the left, matching grouped-list rows. */
@Composable
private fun InsetDivider() {
    HorizontalDivider(
        modifier = Modifier.padding(start = 16.dp),
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f),
    )
}
