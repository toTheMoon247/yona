package com.yona.app.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AssistChip
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.yona.app.core.CostPeriod
import com.yona.app.core.RenewalRepeat
import com.yona.app.core.Tile
import com.yona.app.core.TileDraft
import com.yona.app.core.TileStore
import com.yona.app.core.UrlHelpers
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Create (existing == null) or edit (existing != null) a tile. Reuses one form
 * for both, mirroring the iOS shared form.
 */
/** Prefill the cost field without a trailing ".0" for whole amounts. */
private fun formatAmount(amount: Double): String =
    if (amount % 1.0 == 0.0) amount.toLong().toString() else amount.toString()

private val formDateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.getDefault())

private fun displayDate(iso: String): String =
    runCatching { LocalDate.parse(iso).format(formDateFormatter) }.getOrDefault(iso)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TileFormScreen(existing: Tile?, onDismiss: () -> Unit, onSaved: () -> Unit) {
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current
    val editing = existing != null

    var title by rememberSaveable { mutableStateOf(existing?.title ?: "") }
    var url by rememberSaveable { mutableStateOf(existing?.url ?: "") }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    var costText by rememberSaveable { mutableStateOf(existing?.costAmount?.let { formatAmount(it) } ?: "") }
    var period by rememberSaveable { mutableStateOf(existing?.costPeriod ?: CostPeriod.MONTHLY) }
    var renewalDate by rememberSaveable { mutableStateOf(existing?.renewalDate) }
    var renewalRepeat by rememberSaveable { mutableStateOf(existing?.renewalRepeat) }
    var showDatePicker by remember { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    val canSave = title.isNotBlank() && url.isNotBlank() && !saving

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
            val draft = TileDraft(
                title = title.trim(),
                url = UrlHelpers.normalized(url),
                notes = notes.trim().ifBlank { null },
                costAmount = amount,
                costPeriod = if (amount != null) period else null,
                renewalDate = renewalDate,
                renewalRepeat = if (renewalDate != null) renewalRepeat else null,
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

    Scaffold(
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
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 20.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Spacer(Modifier.height(4.dp))

            if (existing == null) {
                ServiceSearchField(
                    onSelect = { name, domain ->
                        title = name
                        url = domain
                    },
                    enabled = !saving,
                )
                HorizontalDivider()
            }

            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Title") },
                singleLine = true,
                enabled = !saving,
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = url,
                onValueChange = { url = it },
                label = { Text("Website") },
                placeholder = { Text("netflix.com") },
                singleLine = true,
                enabled = !saving,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it },
                label = { Text("Notes (optional)") },
                minLines = 3,
                enabled = !saving,
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = costText,
                onValueChange = { costText = it },
                label = { Text("Cost (optional)") },
                singleLine = true,
                enabled = !saving,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
            )

            if (costText.isNotBlank()) {
                SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                    SegmentedButton(
                        selected = period == CostPeriod.MONTHLY,
                        onClick = { period = CostPeriod.MONTHLY },
                        shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2),
                        enabled = !saving,
                    ) { Text("Monthly") }
                    SegmentedButton(
                        selected = period == CostPeriod.YEARLY,
                        onClick = { period = CostPeriod.YEARLY },
                        shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2),
                        enabled = !saving,
                    ) { Text("Yearly") }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Renewal date (optional)",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
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
                    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                        SegmentedButton(
                            selected = renewalRepeat == null,
                            onClick = { renewalRepeat = null },
                            shape = SegmentedButtonDefaults.itemShape(index = 0, count = 3),
                            enabled = !saving,
                        ) { Text("Never") }
                        SegmentedButton(
                            selected = renewalRepeat == RenewalRepeat.MONTHLY,
                            onClick = { renewalRepeat = RenewalRepeat.MONTHLY },
                            shape = SegmentedButtonDefaults.itemShape(index = 1, count = 3),
                            enabled = !saving,
                        ) { Text("Monthly") }
                        SegmentedButton(
                            selected = renewalRepeat == RenewalRepeat.YEARLY,
                            onClick = { renewalRepeat = RenewalRepeat.YEARLY },
                            shape = SegmentedButtonDefaults.itemShape(index = 2, count = 3),
                            enabled = !saving,
                        ) { Text("Yearly") }
                    }
                } else {
                    TextButton(onClick = { showDatePicker = true }, enabled = !saving) {
                        Text("Pick a date…")
                    }
                }
            }

            error?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
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
