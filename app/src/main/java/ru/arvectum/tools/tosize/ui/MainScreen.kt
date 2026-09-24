package ru.arvectum.tools.tosize.ui

import androidx.compose.foundation.layout.Arrangement
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
                onModeChange = onModeChange,
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
    onSave: () -> Unit,
    onShare: () -> Unit,
) {
    val source = state.source

    Column(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 20.dp),
    ) {
        ProductHeader()
        Spacer(Modifier.height(24.dp))
        ModeChooser(
            mode = state.mode,
            enabled = !state.isWorking,
            onModeChange = onModeChange,
        )
        Spacer(Modifier.height(28.dp))

        if (source == null) {
            EmptyState(
                mode = state.mode,
                isWorking = state.isWorking,
                onPickImage = onPickImage,
            )
            return@Column
        }

        FileCard(source)
        Spacer(Modifier.height(24.dp))

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
private fun ModeChooser(
    mode: ToolMode,
    enabled: Boolean,
    onModeChange: (ToolMode) -> Unit,
) {
    FlowRow(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        FilterChip(
            selected = mode == ToolMode.FILE_SIZE,
            onClick = { onModeChange(ToolMode.FILE_SIZE) },
            label = { Text("По весу") },
            enabled = enabled,
        )
        FilterChip(
            selected = mode == ToolMode.PIXELS,
            onClick = { onModeChange(ToolMode.PIXELS) },
            label = { Text("По пикселям") },
            enabled = enabled,
        )
        FilterChip(
            selected = mode == ToolMode.PASSPORT,
            onClick = { onModeChange(ToolMode.PASSPORT) },
            label = { Text("На паспорт") },
            enabled = enabled,
        )
    }
}

@Composable
private fun EmptyState(
    mode: ToolMode,
    isWorking: Boolean,
    onPickImage: () -> Unit,
) {
    val title = when (mode) {
        ToolMode.FILE_SIZE -> "Фото должно быть не больше нужного размера?"
        ToolMode.PIXELS -> "Нужен точный размер изображения в пикселях?"
        ToolMode.PASSPORT -> "Фото для заявления на паспорт через Госуслуги?"
    }
    val body = when (mode) {
        ToolMode.FILE_SIZE -> "Выберите файл и укажите максимальный вес."
        ToolMode.PIXELS -> "Выберите фото и задайте размер его длинной стороны."
        ToolMode.PASSPORT -> "Подготовим технические параметры и кадр 35×45. Лицо и фон не проверяем."
    }

    Text(title, style = MaterialTheme.typography.headlineSmall)
    Spacer(Modifier.height(12.dp))
    Text(
        text = body,
        style = MaterialTheme.typography.bodyLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Spacer(Modifier.height(28.dp))
    PrimaryAction(
        text = "Выбрать фото",
        enabled = !isWorking,
        busy = isWorking,
        onClick = onPickImage,
    )
    Spacer(Modifier.height(16.dp))
    Text(
        text = "Изображение обрабатывается на этом устройстве.",
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
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

    Text("Не больше", style = MaterialTheme.typography.titleMedium)
    Spacer(Modifier.height(12.dp))

    FlowRow(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        FileSizePresets.forEach { (bytes, label) ->
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
                        Text("От 10 КБ до 50 МБ")
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

    if (source.mimeType == "image/png" && !alreadyFits) {
        Spacer(Modifier.height(16.dp))
        NoticeCard("PNG будет сохранён как JPG. Прозрачность станет белой.")
    }

    Spacer(Modifier.height(24.dp))
    if (alreadyFits) {
        AlreadyFitsCard(
            title = "Уже подходит",
            main = "${formatBytes(source.sizeBytes)} ≤ ${formatBytes(requireNotNull(target))}",
            detail = "Не будем пережимать изображение.",
        )
        Spacer(Modifier.height(16.dp))
        SaveShareActions(
            state = state,
            onSave = onSave,
            onShare = onShare,
        )
    } else {
        PrimaryAction(
            text = target?.let { "Сделать до ${formatBytes(it)}" } ?: "Укажите размер",
            enabled = target != null && !state.isWorking,
            busy = state.isWorking,
            onClick = onCompress,
        )
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

    Text("Длинная сторона", style = MaterialTheme.typography.titleMedium)
    Spacer(Modifier.height(6.dp))
    Text(
        text = "Для прямоугольного фото задаём длинную сторону. Короткая сторона рассчитывается автоматически с сохранением пропорций.",
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Spacer(Modifier.height(12.dp))

    FlowRow(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        PixelPresets.forEach { (pixels, label) ->
            FilterChip(
                selected = !state.isCustomPixels && state.targetLongSide == pixels,
                onClick = { onPreset(pixels) },
                label = { Text(label) },
                enabled = !state.isWorking,
            )
        }
        FilterChip(
            selected = state.isCustomPixels,
            onClick = onCustomMode,
            label = { Text("Свой") },
            enabled = !state.isWorking,
        )
    }

    if (state.isCustomPixels) {
        Spacer(Modifier.height(12.dp))
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
        Spacer(Modifier.height(16.dp))
        DimensionPreviewCard(
            source = source,
            result = resultDimensions,
            alreadyFits = alreadyFits,
        )
    }

    if (source.mimeType == "image/png" && !alreadyFits && target != null) {
        Spacer(Modifier.height(16.dp))
        NoticeCard("После уменьшения PNG будет сохранён как JPG. Прозрачность станет белой.")
    }

    Spacer(Modifier.height(24.dp))
    if (alreadyFits) {
        AlreadyFitsCard(
            title = "Уже меньше выбранного размера",
            main = "${source.width}×${source.height} px",
            detail = "Увеличивать фото не будем.",
        )
        Spacer(Modifier.height(16.dp))
        SaveShareActions(
            state = state,
            onSave = onSave,
            onShare = onShare,
        )
    } else {
        PrimaryAction(
            text = resultDimensions?.let {
                "Сделать ${it.width}×${it.height} px"
            } ?: "Укажите размер",
            enabled = target != null && !state.isWorking,
            busy = state.isWorking,
            onClick = onResize,
        )
    }
}

@Composable
private fun PassportSection(
    state: AppUiState,
    onOpenCrop: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
        ),
    ) {
        Column(Modifier.padding(18.dp)) {
            Text(
                text = "Для заявления на Госуслугах",
                style = MaterialTheme.typography.titleMedium,
            )
            Spacer(Modifier.height(12.dp))
            Text("35×45 мм · 620×797 px · 450 DPI · JPEG")
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Файл: 10 КБ–5 МБ",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }

    Spacer(Modifier.height(16.dp))
    NoticeCard(
        "Меняем только кадр и технические параметры. Положение лица, фон, выражение и другие требования приложение не проверяет.",
    )
    Spacer(Modifier.height(24.dp))
    PrimaryAction(
        text = "Настроить кадр 35×45",
        enabled = !state.isWorking,
        busy = state.isWorking,
        onClick = onOpenCrop,
    )
}

@Composable
private fun DimensionPreviewCard(
    source: SourceImage,
    result: ImageDimensions,
    alreadyFits: Boolean,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
    ) {
        Column(Modifier.padding(14.dp)) {
            Text(
                text = if (alreadyFits) {
                    "Итог без увеличения"
                } else {
                    "Итог"
                },
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = "${result.width}×${result.height} px",
                style = MaterialTheme.typography.titleMedium,
            )
            if (!alreadyFits) {
                Spacer(Modifier.height(4.dp))
                Text(
                    text = "Было ${source.width}×${source.height} px",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
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
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface,
            ),
        ) {
            Column(Modifier.padding(20.dp)) {
                when (result.mode) {
                    ToolMode.FILE_SIZE -> {
                        Text(
                            text = formatBytes(result.outputSizeBytes),
                            style = MaterialTheme.typography.headlineMedium,
                            color = MaterialTheme.colorScheme.primary,
                        )
                        result.targetBytes?.let {
                            Spacer(Modifier.height(6.dp))
                            Text(
                                text = "≤ ${formatBytes(it)}",
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                        Spacer(Modifier.height(16.dp))
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
                        Text(
                            text = "${result.outputWidth}×${result.outputHeight} px",
                            style = MaterialTheme.typography.headlineMedium,
                            color = MaterialTheme.colorScheme.primary,
                        )
                        Spacer(Modifier.height(6.dp))
                        Text(
                            text = formatBytes(result.outputSizeBytes),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Spacer(Modifier.height(16.dp))
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
                        Text(
                            text = "${result.outputWidth}×${result.outputHeight} px",
                            style = MaterialTheme.typography.headlineMedium,
                            color = MaterialTheme.colorScheme.primary,
                        )
                        Spacer(Modifier.height(6.dp))
                        Text(
                            text = "35×45 мм · 450 DPI · JPEG",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Spacer(Modifier.height(16.dp))
                        Text(
                            text = "Размер файла: ${formatBytes(result.outputSizeBytes)}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        }

        if (result.mode == ToolMode.PASSPORT) {
            Spacer(Modifier.height(16.dp))
            NoticeCard(
                "Технические параметры подготовлены. Соответствие лица, фона и позы требованиям ведомства не проверялось.",
            )
        }

        Spacer(Modifier.height(24.dp))
        SaveShareActions(
            state = state,
            onSave = onSave,
            onShare = onShare,
        )

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
private fun SaveShareActions(
    state: AppUiState,
    onSave: () -> Unit,
    onShare: () -> Unit,
) {
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
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
        ),
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
private fun AlreadyFitsCard(
    title: String,
    main: String,
    detail: String,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer,
        ),
    ) {
        Column(Modifier.padding(18.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = main,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = detail,
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
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
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
