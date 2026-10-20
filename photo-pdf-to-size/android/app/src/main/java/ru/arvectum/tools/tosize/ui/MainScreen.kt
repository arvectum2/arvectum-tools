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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import ru.arvectum.tools.tosize.AppUiState
import ru.arvectum.tools.tosize.ImageDimensions
import ru.arvectum.tools.tosize.NormalizedCropRect
import ru.arvectum.tools.tosize.ResultImage
import ru.arvectum.tools.tosize.SizeUnit
import ru.arvectum.tools.tosize.SourceImage
import ru.arvectum.tools.tosize.R
import ru.arvectum.tools.tosize.ToolMode
import ru.arvectum.tools.tosize.calculateLongSideDimensions
import kotlin.math.max
import kotlin.math.roundToInt

private val FileSizePresets = listOf(100_000L, 500_000L, 1_000_000L, 2_000_000L, 5_000_000L)

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
                Spacer(Modifier.height(10.dp))
                if (state.result == null) {
                    ModeSelector(
                        mode = state.mode,
                        enabled = !state.isWorking,
                        onModeChange = onModeChange,
                    )
                    Spacer(Modifier.height(10.dp))
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
                        Text(stringResource(R.string.ok))
                    }
                },
                title = { Text(stringResource(R.string.something_went_wrong)) },
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
            .padding(horizontal = 14.dp)
            .padding(bottom = 4.dp),
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
        Spacer(Modifier.height(10.dp))

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

        Spacer(Modifier.height(2.dp))
        TextButton(
            onClick = onPickImage,
            enabled = !state.isWorking,
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) {
            Text(stringResource(R.string.choose_another_photo))
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
        ToolMode.FILE_SIZE -> stringResource(R.string.compress_to_a_target_file_size)
        ToolMode.PIXELS -> stringResource(R.string.resize_photo)
        ToolMode.PASSPORT -> stringResource(R.string.passport_photo)
    }
    val body = when (mode) {
        ToolMode.FILE_SIZE -> stringResource(R.string.choose_the_maximum_file_size_we_will_handle_the_rest)
        ToolMode.PIXELS -> stringResource(R.string.set_the_longest_edge_the_aspect_ratio_will_be_preserved)
        ToolMode.PASSPORT -> stringResource(R.string.crop_the_photo_and_set_file_parameters_for_a_gosuslugi_application)
    }

    BrandCard {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = body,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(14.dp))
        BrandPrimaryButton(
            text = stringResource(R.string.choose_photo),
            enabled = !isWorking,
            busy = isWorking,
            onClick = onPickImage,
        )
    }

    Spacer(Modifier.height(12.dp))
    Text(
        text = stringResource(R.string.your_photo_is_processed_only_on_this_device),
        modifier = Modifier.fillMaxWidth(),
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
private fun FileCard(source: SourceImage) {
    BrandCard {
        BrandAccentText(stringResource(R.string.selected_photo))
        Spacer(Modifier.height(5.dp))
        Text(
            text = source.displayName,
            style = MaterialTheme.typography.titleMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Spacer(Modifier.height(5.dp))
        Text(
            text = stringResource(R.string.source_metadata, formatBytes(source.sizeBytes), source.width, source.height),
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
            eyebrow = stringResource(R.string.by_file_size),
            title = stringResource(R.string.target_file_size),
        )
        Spacer(Modifier.height(10.dp))

        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            FileSizePresets.forEach { bytes ->
                ChoiceChip(
                    label = formatBytes(bytes),
                    selected = !state.isCustomTarget && state.targetBytes == bytes,
                    enabled = !state.isWorking,
                    onClick = { onPreset(bytes) },
                )
            }
            ChoiceChip(
                label = stringResource(R.string.custom),
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
                    label = { Text(stringResource(R.string.size)) },
                    placeholder = { Text("750") },
                    supportingText = {
                        if (state.customValue.isNotBlank() && state.targetBytes == null) {
                            Text(stringResource(R.string.between_10_kb_and_50_mb))
                        }
                    },
                    isError = state.customValue.isNotBlank() && state.targetBytes == null,
                    enabled = !state.isWorking,
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Done,
                    ),
                )
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    ChoiceChip(
                        label = stringResource(R.string.kb),
                        selected = state.customUnit == SizeUnit.KB,
                        enabled = !state.isWorking,
                        onClick = { onCustomUnit(SizeUnit.KB) },
                    )
                    ChoiceChip(
                        label = stringResource(R.string.mb),
                        selected = state.customUnit == SizeUnit.MB,
                        enabled = !state.isWorking,
                        onClick = { onCustomUnit(SizeUnit.MB) },
                    )
                }
            }
        }

        if (source.mimeType == "image/png" && !alreadyFits) {
            Spacer(Modifier.height(14.dp))
            InlineNotice(stringResource(R.string.png_will_be_saved_as_jpg_transparent_areas_will_become_white))
        }

        Spacer(Modifier.height(18.dp))
        if (alreadyFits) {
            StatusBlock(
                value = "${formatBytes(source.sizeBytes)} ≤ ${formatBytes(requireNotNull(target))}",
                detail = stringResource(R.string.the_photo_already_fits_no_compression_needed),
            )
            Spacer(Modifier.height(14.dp))
            SaveShareActions(state, onSave, onShare)
        } else {
            BrandPrimaryButton(
                text = target?.let { stringResource(R.string.compress_to, formatBytes(it)) } ?: stringResource(R.string.enter_a_size),
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
            eyebrow = stringResource(R.string.by_dimensions),
            title = stringResource(R.string.dimensions_in_pixels),
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = stringResource(R.string.set_the_longest_edge_the_aspect_ratio_will_be_preserved),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(10.dp))

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
                label = stringResource(R.string.custom),
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
                label = { Text(stringResource(R.string.longest_edge)) },
                placeholder = { Text("800") },
                supportingText = {
                    if (state.customPixelsValue.isNotBlank() && target == null) {
                        Text(stringResource(R.string.between_32_and_12_000_px))
                    }
                },
                isError = state.customPixelsValue.isNotBlank() && target == null,
                enabled = !state.isWorking,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Number,
                    imeAction = ImeAction.Done,
                ),
            )
        }

        if (resultDimensions != null) {
            Spacer(Modifier.height(14.dp))
            StatusBlock(
                value = "${resultDimensions.width}×${resultDimensions.height} px",
                detail = if (alreadyFits) {
                    stringResource(R.string.the_image_already_fits_no_enlargement_needed)
                } else {
                    stringResource(R.string.original_dimensions, source.width, source.height)
                },
            )
        }

        if (source.mimeType == "image/png" && !alreadyFits && target != null) {
            Spacer(Modifier.height(14.dp))
            InlineNotice(stringResource(R.string.after_resizing_png_will_be_saved_as_jpg))
        }

        Spacer(Modifier.height(18.dp))
        if (alreadyFits) {
            SaveShareActions(state, onSave, onShare)
        } else {
            BrandPrimaryButton(
                text = resultDimensions?.let {
                    stringResource(R.string.resize_to, it.width, it.height)
                } ?: stringResource(R.string.enter_a_size),
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
            eyebrow = stringResource(R.string.passport_photo_label),
            title = stringResource(R.string.for_a_gosuslugi_application),
        )
        Spacer(Modifier.height(14.dp))
        SpecRow(stringResource(R.string.format), stringResource(R.string.passport_measurements))
        SpecRow(stringResource(R.string.size), "620×797 px")
        SpecRow(stringResource(R.string.resolution), "450 DPI")
        SpecRow(stringResource(R.string.file), stringResource(R.string.passport_file_specs))
        Spacer(Modifier.height(14.dp))
        InlineNotice(
            stringResource(R.string.we_only_adjust_cropping_and_file_properties_we_do_not_verify_face_background_or_pose),
        )
        Spacer(Modifier.height(18.dp))
        BrandPrimaryButton(
            text = stringResource(R.string.crop_photo_to_35_45),
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
            .padding(horizontal = 14.dp)
            .padding(bottom = 4.dp),
    ) {
        BrandCard {
            BrandAccentText(
                resultModeLabel(
                    mode = result.mode,
                    alreadyFit = result.alreadyFit,
                ),
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = if (result.alreadyFit) stringResource(R.string.already_fits) else stringResource(R.string.done),
                style = MaterialTheme.typography.titleLarge,
            )
            Spacer(Modifier.height(12.dp))

            when (result.mode) {
                ToolMode.FILE_SIZE -> {
                    ResultHero(formatBytes(result.outputSizeBytes))
                    result.targetBytes?.let {
                        Text(
                            text = stringResource(R.string.size_limit, formatBytes(it)),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = if (result.alreadyFit) {
                            stringResource(R.string.the_file_was_not_compressed_quality_is_unchanged)
                        } else {
                            stringResource(R.string.reduction_summary, formatBytes(result.source.sizeBytes), reduction)
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                ToolMode.PIXELS -> {
                    ResultHero("${result.outputWidth}×${result.outputHeight} px")
                    Text(
                        text = stringResource(R.string.result_file_size, formatBytes(result.outputSizeBytes)),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = if (result.alreadyFit) {
                            stringResource(R.string.the_image_was_not_enlarged)
                        } else {
                            stringResource(R.string.original_dimensions, result.source.width, result.source.height)
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                ToolMode.PASSPORT -> {
                    ResultHero("${result.outputWidth}×${result.outputHeight} px")
                    Text(
                        text = stringResource(R.string.passport_ready_specs),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = stringResource(R.string.result_file_size, formatBytes(result.outputSizeBytes)),
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
                stringResource(R.string.file_parameters_are_ready_face_background_and_pose_have_not_been_checked),
            )
        }

        Spacer(Modifier.height(2.dp))
        TextButton(
            onClick = onReset,
            enabled = !state.isWorking,
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) {
            Text(stringResource(R.string.another_photo))
        }
        TextButton(
            onClick = onBack,
            enabled = !state.isWorking,
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) {
            Text(
                if (result.mode == ToolMode.PASSPORT) {
                    stringResource(R.string.start_over)
                } else {
                    stringResource(R.string.change_size)
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
                color = MaterialTheme.colorScheme.secondary,
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
        color = MaterialTheme.colorScheme.secondary,
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
        text = stringResource(R.string.save),
        enabled = !state.isWorking,
        busy = state.isWorking,
        onClick = onSave,
    )
    Spacer(Modifier.height(8.dp))
    BrandSecondaryButton(
        text = stringResource(R.string.share),
        enabled = !state.isWorking,
        onClick = onShare,
    )
    if (state.saved) {
        Spacer(Modifier.height(10.dp))
        Text(
            text = stringResource(R.string.saved),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

@Composable
private fun resultModeLabel(mode: ToolMode, alreadyFit: Boolean): String {
    val modeLabel = when (mode) {
        ToolMode.FILE_SIZE -> stringResource(R.string.by_file_size)
        ToolMode.PIXELS -> stringResource(R.string.by_dimensions)
        ToolMode.PASSPORT -> stringResource(R.string.passport_photo_label)
    }
    val status = if (alreadyFit) stringResource(R.string.unchanged) else stringResource(R.string.done_label)
    return "$modeLabel · $status"
}

data class DecimalFileSize(val inKilobytes: Boolean, val value: Double)

fun decimalFileSize(bytes: Long): DecimalFileSize =
    if (bytes < 1_000_000L) {
        DecimalFileSize(inKilobytes = true, value = (bytes / 1_000.0).roundToInt().toDouble())
    } else {
        DecimalFileSize(inKilobytes = false, value = bytes / 1_000_000.0)
    }

@Composable
fun formatBytes(bytes: Long): String {
    val size = decimalFileSize(bytes)
    return when {
        size.inKilobytes -> stringResource(R.string.size_in_kb, size.value.toInt())
        size.value == size.value.roundToInt().toDouble() ->
            stringResource(R.string.size_in_mb, size.value.toInt())
        else -> stringResource(R.string.size_in_mb_decimal, size.value)
    }
}
