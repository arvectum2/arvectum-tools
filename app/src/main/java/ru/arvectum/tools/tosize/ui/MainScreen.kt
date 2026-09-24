package ru.arvectum.tools.tosize.ui

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.material3.MaterialTheme
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
import ru.arvectum.tools.tosize.ImageDimensions
import ru.arvectum.tools.tosize.NormalizedCropRect
import ru.arvectum.tools.tosize.ResultImage
import ru.arvectum.tools.tosize.SizeUnit
import ru.arvectum.tools.tosize.SourceImage
import ru.arvectum.tools.tosize.ToolMode
import ru.arvectum.tools.tosize.calculateLongSideDimensions
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt

private val FileSizePresets = listOf(
    100_000L to "100 КБ",
    500_000L to "500 КБ",
    1_000_000L to "1 МБ",
    2_000_000L to "2 МБ",
    5_000_000L to "5 МБ",
)

private val PixelPresets = listOf(
    600 to "600 px",
    450 to "450 px",
    300 to "300 px",
)

@Composable
fun MainScreen(
    state: AppUiState,
    onModeChange: (ToolMode) -> Unit,
    onPickImage: () -> Unit,
    onPreset: (Long) -> Unit,
    onCustomMode: () -> Unit,
    onCustomValue: (String) -> Unit,
    onCustomUnit: (SizeUnit) -> Unit,
    onPixelPreset: (Int) -> Unit,
    onCustomPixelsMode: () -> Unit,
    onCustomPixelsValue: (String) -> Unit,
    onCompressByBytes: () -> Unit,
    onResizeByPixels: () -> Unit,
    onOpenPassportCrop: () -> Unit,
    onPassportCropCancel: () -> Unit,
    onPassportCropConfirm: (NormalizedCropRect) -> Unit,
    onSave: () -> Unit,
    onShare: () -> Unit,
    onBackToSelection: () -> Unit,
    onReset: () -> Unit,
    onDismissError: () -> Unit,
) {
    val source = state.source
    if (state.passportCropOpen && source != null) {
        PassportCropScreen(
            source = source,
            onCancel = onPassportCropCancel,
            onConfirm = onPassportCropConfirm,
        )
        return
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding(),
        ) {
            Column(
                modifier = Modifier.padding(
                    start = 18.dp,
                    end = 18.dp,
                    top = 12.dp,
                ),
            ) {
                BrandHeader()
                Spacer(Modifier.height(16.dp))
                if (state.result == null) {
                    ModeSelector(
                        mode = state.mode,
                        enabled = !state.isWorking,
                        onModeChange = onModeChange,
                    )
                    Spacer(Modifier.height(16.dp))
                }
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) {
                if (state.result != null) {
                    ResultContent(
                        state = state,
                        result = state.result,
                        onSave = onSave,
                        onShare = onShare,
                        onBack = onBackToSelection,
                        onReset = onReset,
                    )
                } else {
                    SelectionContent(
                        state = state,
                        onPickImage = onPickImage,
                        onPreset = onPreset,
                        onCustomMode = onCustomMode,
                        onCustomValue = onCustomValue,
                        onCustomUnit = onCustomUnit,
                        onPixelPreset = onPixelPreset,
                        onCustomPixelsMode = onCustomPixelsMode,
                        onCustomPixelsValue = onCustomPixelsValue,
                        onCompressByBytes = onCompressByBytes,
                        onResizeByPixels = onResizeByPixels,
                        onOpenPassportCrop = onOpenPassportCrop,
                        onSave = onSave,
                        onShare = onShare,
                    )
                }
            }

            BrandFooter(
                modifier = Modifier.padding(horizontal = 18.dp),
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
private fun SelectionContent(
    state: AppUiState,
    onPickImage: () -> Unit,
    onPreset: (Long) -> Unit,
    onCustomMode: () -> Unit,
    onCustomValue: (String) -> Unit,
    onCustomUnit: (SizeUnit) -> Unit,
    onPixelPreset: (Int) -> Unit,
    onCustomPixelsMode: () -> Unit,
    onCustomPixelsValue: (String) -> Unit,
    onCompressByBytes: () -> Unit,
    onResizeByPixels: () -> Unit,
    onOpenPassportCrop: () -> Unit,
    onSave: () -> Unit,
    onShare: () -> Unit,
) {
    val source = state.source

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 18.dp)
            .padding(bottom = 12.dp),
    ) {
        if (source == null) {
            EmptyState(
                mode = state.mode,
                isWorking = state.isWorking,
                onPickImage = onPickImage,
            )
            return@Column
        }

        FileCard(source)
        Spacer(Modifier.height(16.dp))

        when (state.mode) {
            ToolMode.FILE_SIZE -> FileSizeSection(
                state = state,
                source = source,
                onPreset = onPreset,
                onCustomMode = onCustomMode,
                onCustomValue = onCustomValue,
                onCustomUnit = onCustomUnit,
                onCompress = onCompressByBytes,
                onSave = onSave,
                onShare = onShare,
            )

            ToolMode.PIXELS -> PixelSection(
                state = state,
                source = source,
                onPreset = onPixelPreset,
                onCustomMode = onCustomPixelsMode,
                onCustomValue = onCustomPixelsValue,
                onResize = onResizeByPixels,
                onSave = onSave,
                onShare = onShare,
            )

            ToolMode.PASSPORT -> PassportSection(
                state = state,
                onOpenCrop = onOpenPassportCrop,
            )
        }

        Spacer(Modifier.height(6.dp))
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
private fun EmptyState(
    mode: ToolMode,
    isWorking: Boolean,
    onPickImage: () -> Unit,
) {
    val title = when (mode) {
        ToolMode.FILE_SIZE -> "Уложить фото в лимит"
        ToolMode.PIXELS -> "Задать размер в пикселях"
        ToolMode.PASSPORT -> "Подготовить фото на паспорт"
    }
    val body = when (mode) {
        ToolMode.FILE_SIZE -> "Укажите максимальный вес файла — приложение само подберёт сжатие."
        ToolMode.PIXELS -> "Задайте длинную сторону. Короткую сторону рассчитаем автоматически."
        ToolMode.PASSPORT -> "Подготовим технические параметры для заявления на Госуслугах."
    }

    BrandCard {
        BrandAccentText("LOCAL FIRST")
        Spacer(Modifier.height(8.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = body,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(20.dp))
        BrandPrimaryButton(
            text = "Выбрать фото",
            enabled = !isWorking,
            busy = isWorking,
            onClick = onPickImage,
        )
    }

    Spacer(Modifier.height(12.dp))
    Text(
        text = "Файл обрабатывается только на этом устройстве.",
        modifier = Modifier.fillMaxWidth(),
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
private fun FileCard(source: SourceImage) {
    BrandCard {
        BrandAccentText("ФАЙЛ")
        Spacer(Modifier.height(7.dp))
        Text(
            text = source.displayName,
            style = MaterialTheme.typography.titleMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Spacer(Modifier.height(5.dp))
        Text(
            text = "${formatBytes(source.sizeBytes)}  ·  ${source.width}×${source.height} px",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun FileSizeSection(
    state: AppUiState,
    source: SourceImage,
    onPreset: (Long) -> Unit,
    onCustomMode: () -> Unit,
    onCustomValue: (String) -> Unit,
    onCustomUnit: (SizeUnit) -> Unit,
    onCompress: () -> Unit,
    onSave: () -> Unit,
    onShare: () -> Unit,
) {
    val target = state.targetBytes
    val alreadyFits = target != null && source.sizeBytes <= target

    BrandCard {
        SectionTitle(
            eyebrow = "ПО ВЕСУ",
            title = "Максимальный размер",
        )
        Spacer(Modifier.height(14.dp))

        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            FileSizePresets.forEach { (bytes, label) ->
                ChoiceChip(
                    label = label,
                    selected = !state.isCustomTarget && state.targetBytes == bytes,
                    enabled = !state.isWorking,
                    onClick = { onPreset(bytes) },
                )
            }
            ChoiceChip(
                label = "Свой",
                selected = state.isCustomTarget,
                enabled = !state.isWorking,
                onClick = onCustomMode,
            )
        }

        if (state.isCustomTarget) {
            Spacer(Modifier.height(14.dp))
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
                            Text("От 10 КБ до 50 МБ")
                        }
                    },
                    isError = state.customValue.isNotBlank() && state.targetBytes == null,
                    enabled = !state.isWorking,
                )
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    ChoiceChip(
                        label = "КБ",
                        selected = state.customUnit == SizeUnit.KB,
                        enabled = !state.isWorking,
                        onClick = { onCustomUnit(SizeUnit.KB) },
                    )
                    ChoiceChip(
                        label = "МБ",
                        selected = state.customUnit == SizeUnit.MB,
                        enabled = !state.isWorking,
                        onClick = { onCustomUnit(SizeUnit.MB) },
                    )
                }
            }
        }

        if (source.mimeType == "image/png" && !alreadyFits) {
            Spacer(Modifier.height(14.dp))
            InlineNotice("PNG будет сохранён как JPG. Прозрачность станет белой.")
        }

        Spacer(Modifier.height(18.dp))
        if (alreadyFits) {
            StatusBlock(
                value = "${formatBytes(source.sizeBytes)} ≤ ${formatBytes(requireNotNull(target))}",
                detail = "Файл уже подходит. Пережимать его не будем.",
            )
            Spacer(Modifier.height(14.dp))
            SaveShareActions(state, onSave, onShare)
        } else {
            BrandPrimaryButton(
                text = target?.let { "Сделать до ${formatBytes(it)}" } ?: "Укажите размер",
                enabled = target != null && !state.isWorking,
                busy = state.isWorking,
                onClick = onCompress,
            )
        }
    }
}

@Composable
private fun PixelSection(
    state: AppUiState,
    source: SourceImage,
    onPreset: (Int) -> Unit,
    onCustomMode: () -> Unit,
    onCustomValue: (String) -> Unit,
    onResize: () -> Unit,
    onSave: () -> Unit,
    onShare: () -> Unit,
) {
    val target = state.targetLongSide
    val sourceLongSide = max(source.width, source.height)
    val alreadyFits = target != null && sourceLongSide <= target
    val resultDimensions = target?.let {
        if (alreadyFits) {
            ImageDimensions(source.width, source.height)
        } else {
            calculateLongSideDimensions(source.width, source.height, it)
        }
    }

    BrandCard {
        SectionTitle(
            eyebrow = "ПО ПИКСЕЛЯМ",
            title = "Длинная сторона",
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = "Короткая сторона рассчитывается автоматически с сохранением пропорций.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(14.dp))

        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            PixelPresets.forEach { (pixels, label) ->
                ChoiceChip(
                    label = label,
                    selected = !state.isCustomPixels && state.targetLongSide == pixels,
                    enabled = !state.isWorking,
                    onClick = { onPreset(pixels) },
                )
            }
            ChoiceChip(
                label = "Свой",
                selected = state.isCustomPixels,
                enabled = !state.isWorking,
                onClick = onCustomMode,
            )
        }

        if (state.isCustomPixels) {
            Spacer(Modifier.height(14.dp))
            OutlinedTextField(
                value = state.customPixelsValue,
                onValueChange = onCustomValue,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                suffix = { Text("px") },
                label = { Text("Длинная сторона") },
                placeholder = { Text("800") },
                supportingText = {
                    if (state.customPixelsValue.isNotBlank() && target == null) {
                        Text("От 32 до 12 000 px")
                    }
                },
                isError = state.customPixelsValue.isNotBlank() && target == null,
                enabled = !state.isWorking,
            )
        }

        if (resultDimensions != null) {
            Spacer(Modifier.height(14.dp))
            StatusBlock(
                value = "${resultDimensions.width}×${resultDimensions.height} px",
                detail = if (alreadyFits) {
                    "Фото уже меньше выбранного размера. Увеличивать его не будем."
                } else {
                    "Было ${source.width}×${source.height} px"
                },
            )
        }

        if (source.mimeType == "image/png" && !alreadyFits && target != null) {
            Spacer(Modifier.height(14.dp))
            InlineNotice("После уменьшения PNG будет сохранён как JPG.")
        }

        Spacer(Modifier.height(18.dp))
        if (alreadyFits) {
            SaveShareActions(state, onSave, onShare)
        } else {
            BrandPrimaryButton(
                text = resultDimensions?.let {
                    "Сделать ${it.width}×${it.height} px"
                } ?: "Укажите размер",
                enabled = target != null && !state.isWorking,
                busy = state.isWorking,
                onClick = onResize,
            )
        }
    }
}

@Composable
private fun PassportSection(
    state: AppUiState,
    onOpenCrop: () -> Unit,
) {
    BrandCard {
        SectionTitle(
            eyebrow = "НА ПАСПОРТ",
            title = "Для заявления на Госуслугах",
        )
        Spacer(Modifier.height(14.dp))
        SpecRow("Формат", "35×45 мм")
        SpecRow("Размер", "620×797 px")
        SpecRow("Плотность", "450 DPI")
        SpecRow("Файл", "JPEG · 10 КБ–5 МБ")
        Spacer(Modifier.height(14.dp))
        InlineNotice(
            "Меняем только кадр и технические параметры. Лицо, фон и позу не проверяем.",
        )
        Spacer(Modifier.height(18.dp))
        BrandPrimaryButton(
            text = "Настроить кадр 35×45",
            enabled = !state.isWorking,
            busy = state.isWorking,
            onClick = onOpenCrop,
        )
    }
}

@Composable
private fun ResultContent(
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
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 18.dp)
            .padding(bottom = 12.dp),
    ) {
        BrandCard {
            BrandAccentText(
                if (result.alreadyFit) "УЖЕ ПОДХОДИТ" else "ГОТОВО",
            )
            Spacer(Modifier.height(8.dp))

            when (result.mode) {
                ToolMode.FILE_SIZE -> {
                    ResultHero(formatBytes(result.outputSizeBytes))
                    result.targetBytes?.let {
                        Text(
                            text = "Лимит: ${formatBytes(it)}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = if (result.alreadyFit) {
                            "Файл не пережимался — качество осталось исходным."
                        } else {
                            "Было ${formatBytes(result.source.sizeBytes)} · меньше на ${reduction}%"
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                ToolMode.PIXELS -> {
                    ResultHero("${result.outputWidth}×${result.outputHeight} px")
                    Text(
                        text = "Вес файла: ${formatBytes(result.outputSizeBytes)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = if (result.alreadyFit) {
                            "Фото не увеличивалось."
                        } else {
                            "Было ${result.source.width}×${result.source.height} px"
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                ToolMode.PASSPORT -> {
                    ResultHero("${result.outputWidth}×${result.outputHeight} px")
                    Text(
                        text = "35×45 мм · 450 DPI · JPEG",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = "Вес файла: ${formatBytes(result.outputSizeBytes)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            Spacer(Modifier.height(18.dp))
            SaveShareActions(state, onSave, onShare)
        }

        if (result.mode == ToolMode.PASSPORT) {
            Spacer(Modifier.height(12.dp))
            InlineNotice(
                "Технические параметры подготовлены. Соответствие лица, фона и позы требованиям ведомства не проверялось.",
            )
        }

        Spacer(Modifier.height(6.dp))
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
            Text(
                if (result.mode == ToolMode.PASSPORT) {
                    "Настроить заново"
                } else {
                    "Изменить размер"
                },
            )
        }
    }
}

@Composable
private fun SectionTitle(
    eyebrow: String,
    title: String,
) {
    BrandAccentText(eyebrow)
    Spacer(Modifier.height(5.dp))
    Text(
        text = title,
        style = MaterialTheme.typography.titleMedium,
    )
}

@Composable
private fun ChoiceChip(
    label: String,
    selected: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(12.dp),
        color = if (selected) {
            MaterialTheme.colorScheme.primary
        } else {
            MaterialTheme.colorScheme.background
        },
        contentColor = if (selected) {
            MaterialTheme.colorScheme.onPrimary
        } else {
            MaterialTheme.colorScheme.onBackground
        },
        border = BorderStroke(
            1.dp,
            if (selected) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.outlineVariant
            },
        ),
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(
                horizontal = 13.dp,
                vertical = 10.dp,
            ),
            style = MaterialTheme.typography.labelMedium,
        )
    }
}

@Composable
private fun StatusBlock(
    value: String,
    detail: String,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.background,
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant,
        ),
    ) {
        Column(Modifier.padding(14.dp)) {
            Text(
                text = value,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = detail,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun InlineNotice(text: String) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.background,
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant,
        ),
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(13.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun SpecRow(
    label: String,
    value: String,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 5.dp),
    ) {
        Text(
            text = label,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            text = value,
            fontWeight = FontWeight.SemiBold,
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}

@Composable
private fun ResultHero(value: String) {
    Text(
        text = value,
        style = MaterialTheme.typography.headlineMedium,
        color = MaterialTheme.colorScheme.primary,
    )
    Spacer(Modifier.height(5.dp))
}

@Composable
private fun SaveShareActions(
    state: AppUiState,
    onSave: () -> Unit,
    onShare: () -> Unit,
) {
    BrandPrimaryButton(
        text = "Сохранить",
        enabled = !state.isWorking,
        busy = state.isWorking,
        onClick = onSave,
    )
    Spacer(Modifier.height(8.dp))
    BrandSecondaryButton(
        text = "Поделиться",
        enabled = !state.isWorking,
        onClick = onShare,
    )
    if (state.saved) {
        Spacer(Modifier.height(10.dp))
        Text(
            text = "✓ Сохранено",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.primary,
        )
    }
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
