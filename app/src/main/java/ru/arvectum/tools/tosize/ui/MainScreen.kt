package ru.arvectum.tools.tosize.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import ru.arvectum.tools.tosize.AppUiState
import ru.arvectum.tools.tosize.ResultImage
import ru.arvectum.tools.tosize.SizeUnit
import ru.arvectum.tools.tosize.SourceImage
import java.util.Locale
import kotlin.math.roundToInt

private val Presets = listOf(
    100_000L to "100 КБ",
    500_000L to "500 КБ",
    1_000_000L to "1 МБ",
    2_000_000L to "2 МБ",
    5_000_000L to "5 МБ",
)

@Composable
fun MainScreen(
    state: AppUiState,
    onPickImage: () -> Unit,
    onPreset: (Long) -> Unit,
    onCustomMode: () -> Unit,
    onCustomValue: (String) -> Unit,
    onCustomUnit: (SizeUnit) -> Unit,
    onCompress: () -> Unit,
    onSave: () -> Unit,
    onShare: () -> Unit,
    onBackToSelection: () -> Unit,
    onReset: () -> Unit,
    onDismissError: () -> Unit,
) {
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background,
    ) {
        if (state.result != null) {
            ResultScreen(
                state = state,
                result = state.result,
                onSave = onSave,
                onShare = onShare,
                onBack = onBackToSelection,
                onReset = onReset,
            )
        } else {
            SelectionScreen(
                state = state,
                onPickImage = onPickImage,
                onPreset = onPreset,
                onCustomMode = onCustomMode,
                onCustomValue = onCustomValue,
                onCustomUnit = onCustomUnit,
                onCompress = onCompress,
                onSave = onSave,
                onShare = onShare,
            )
        }

        if (state.error != null) {
            AlertDialog(
                onDismissRequest = onDismissError,
                confirmButton = {
                    TextButton(onClick = onDismissError) {
                        Text("Понятно")
                    }
                },
                title = { Text("Не получилось") },
                text = { Text(state.error) },
            )
        }
    }
}

@Composable
private fun SelectionScreen(
    state: AppUiState,
    onPickImage: () -> Unit,
    onPreset: (Long) -> Unit,
    onCustomMode: () -> Unit,
    onCustomValue: (String) -> Unit,
    onCustomUnit: (SizeUnit) -> Unit,
    onCompress: () -> Unit,
    onSave: () -> Unit,
    onShare: () -> Unit,
) {
    val source = state.source
    val target = state.targetBytes
    val alreadyFits = source != null && target != null && source.sizeBytes <= target

    Column(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 20.dp),
    ) {
        ProductHeader()

        Spacer(Modifier.height(32.dp))

        if (source == null) {
            Text(
                text = "Фото должно быть не больше нужного размера?",
                style = MaterialTheme.typography.headlineSmall,
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "Выберите файл — всё остальное приложение сделает само.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(28.dp))
            PrimaryAction(
                text = "Выбрать фото",
                enabled = !state.isWorking,
                busy = state.isWorking,
                onClick = onPickImage,
            )
            Spacer(Modifier.height(16.dp))
            Text(
                text = "Изображение обрабатывается на этом устройстве.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            return@Column
        }

        FileCard(source)
        Spacer(Modifier.height(24.dp))

        Text("Не больше", style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(12.dp))

        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Presets.forEach { (bytes, label) ->
                FilterChip(
                    selected = !state.isCustomTarget && state.targetBytes == bytes,
                    onClick = { onPreset(bytes) },
                    label = { Text(label) },
                    enabled = !state.isWorking,
                )
            }
            FilterChip(
                selected = state.isCustomTarget,
                onClick = onCustomMode,
                label = { Text("Свой") },
                enabled = !state.isWorking,
            )
        }

        if (state.isCustomTarget) {
            Spacer(Modifier.height(12.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OutlinedTextField(
                    value = state.customValue,
                    onValueChange = onCustomValue,
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    label = { Text("Размер") },
                    placeholder = { Text("750") },
                    supportingText = {
                        if (state.customValue.isNotBlank() && state.targetBytes == null) {
                            Text("Допустимо от 10 КБ до 50 МБ")
                        }
                    },
                    isError = state.customValue.isNotBlank() && state.targetBytes == null,
                    enabled = !state.isWorking,
                )
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    FilterChip(
                        selected = state.customUnit == SizeUnit.KB,
                        onClick = { onCustomUnit(SizeUnit.KB) },
                        label = { Text("КБ") },
                        enabled = !state.isWorking,
                    )
                    FilterChip(
                        selected = state.customUnit == SizeUnit.MB,
                        onClick = { onCustomUnit(SizeUnit.MB) },
                        label = { Text("МБ") },
                        enabled = !state.isWorking,
                    )
                }
            }
        }

        if (source.mimeType == "image/png") {
            Spacer(Modifier.height(16.dp))
            NoticeCard(
                "PNG будет сохранён как JPG. Прозрачность, если она есть, станет белой.",
            )
        }

        Spacer(Modifier.height(24.dp))

        if (alreadyFits) {
            FitsCard(source, target)
            Spacer(Modifier.height(16.dp))
            Button(
                onClick = onSave,
                enabled = !state.isWorking,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                Text("Сохранить")
            }
            Spacer(Modifier.height(8.dp))
            OutlinedButton(
                onClick = onShare,
                enabled = !state.isWorking,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                Text("Поделиться")
            }
            if (state.saved) {
                Spacer(Modifier.height(12.dp))
                SuccessText()
            }
        } else {
            PrimaryAction(
                text = target?.let { "Сделать до ${formatBytes(it)}" } ?: "Укажите размер",
                enabled = target != null && !state.isWorking,
                busy = state.isWorking,
                onClick = onCompress,
            )
        }

        Spacer(Modifier.height(12.dp))
        TextButton(
            onClick = onPickImage,
            enabled = !state.isWorking,
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) {
            Text("Выбрать другое фото")
        }
    }
}

@Composable
private fun ResultScreen(
    state: AppUiState,
    result: ResultImage,
    onSave: () -> Unit,
    onShare: () -> Unit,
    onBack: () -> Unit,
    onReset: () -> Unit,
) {
    val reduction = if (result.source.sizeBytes > 0) {
        (100.0 - result.outputSizeBytes.toDouble() / result.source.sizeBytes.toDouble() * 100.0)
            .roundToInt()
            .coerceAtLeast(0)
    } else {
        0
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 20.dp),
    ) {
        ProductHeader()
        Spacer(Modifier.height(32.dp))

        Text(
            text = if (result.alreadyFit) "Уже подходит" else "Готово",
            style = MaterialTheme.typography.headlineSmall,
        )
        Spacer(Modifier.height(20.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        ) {
            Column(Modifier.padding(20.dp)) {
                Text(
                    text = formatBytes(result.outputSizeBytes),
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.primary,
                )
                Spacer(Modifier.height(6.dp))
                Text(
                    text = "≤ ${formatBytes(result.targetBytes)}",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                if (!result.alreadyFit) {
                    Spacer(Modifier.height(16.dp))
                    Text(
                        text = "Было ${formatBytes(result.source.sizeBytes)} · меньше на ${reduction}%",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                } else {
                    Spacer(Modifier.height(16.dp))
                    Text(
                        text = "Файл не пережимался — качество осталось исходным.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }

        Spacer(Modifier.height(24.dp))
        Button(
            onClick = onSave,
            enabled = !state.isWorking,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            if (state.isWorking) {
                CircularProgressIndicator(
                    modifier = Modifier.height(22.dp),
                    strokeWidth = 2.dp,
                )
            } else {
                Text("Сохранить")
            }
        }

        Spacer(Modifier.height(8.dp))
        OutlinedButton(
            onClick = onShare,
            enabled = !state.isWorking,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            Text("Поделиться")
        }

        if (state.saved) {
            Spacer(Modifier.height(12.dp))
            SuccessText()
        }

        Spacer(Modifier.height(12.dp))
        TextButton(
            onClick = onReset,
            enabled = !state.isWorking,
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) {
            Text("Ещё фото")
        }
        TextButton(
            onClick = onBack,
            enabled = !state.isWorking,
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) {
            Text("Изменить размер")
        }
    }
}

@Composable
private fun ProductHeader() {
    Column {
        Text(
            text = "До размера",
            style = MaterialTheme.typography.headlineSmall,
        )
        Text(
            text = "by Arvectum",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.Medium,
        )
    }
}

@Composable
private fun FileCard(source: SourceImage) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
    ) {
        Column(Modifier.padding(16.dp)) {
            Text(
                text = source.displayName,
                style = MaterialTheme.typography.titleMedium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = "${formatBytes(source.sizeBytes)} · ${source.width}×${source.height}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun FitsCard(source: SourceImage, target: Long) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
    ) {
        Column(Modifier.padding(18.dp)) {
            Text(
                text = "Уже подходит",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = "${formatBytes(source.sizeBytes)} ≤ ${formatBytes(target)}",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = "Не будем пережимать изображение.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
        }
    }
}

@Composable
private fun NoticeCard(text: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(14.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun PrimaryAction(
    text: String,
    enabled: Boolean,
    busy: Boolean,
    onClick: () -> Unit,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        shape = RoundedCornerShape(16.dp),
    ) {
        if (busy) {
            CircularProgressIndicator(
                modifier = Modifier.height(22.dp),
                strokeWidth = 2.dp,
            )
        } else {
            Text(text)
        }
    }
}

@Composable
private fun SuccessText() {
    Text(
        text = "✓ Сохранено",
        modifier = Modifier.fillMaxWidth(),
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.primary,
    )
}

fun formatBytes(bytes: Long): String {
    return if (bytes < 1_000_000L) {
        "${(bytes / 1_000.0).roundToInt()} КБ"
    } else {
        val value = bytes / 1_000_000.0
        if (value == value.roundToInt().toDouble()) {
            "${value.roundToInt()} МБ"
        } else {
            String.format(Locale.forLanguageTag("ru-RU"), "%.2f МБ", value)
        }
    }
}
