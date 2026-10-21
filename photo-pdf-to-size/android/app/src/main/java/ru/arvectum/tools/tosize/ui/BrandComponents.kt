package ru.arvectum.tools.tosize.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import ru.arvectum.tools.tosize.R
import ru.arvectum.tools.tosize.ToolMode

@Composable
fun BrandHeader(
    modifier: Modifier = Modifier,
    title: String? = null,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        color = ArvectumDeepNavy,
        contentColor = ArvectumWhite,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(
                painter = painterResource(R.drawable.arvectum_wordmark),
                contentDescription = stringResource(R.string.arvectum_logo),
                modifier = Modifier
                    .width(102.dp)
                    .height(30.dp),
                contentScale = ContentScale.Fit,
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = title ?: stringResource(R.string.photo_resizer),
                color = ArvectumWhite,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.End,
            )
        }
    }
}

@Composable
fun BrandFooter(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(34.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "Arvectum.com",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            letterSpacing = 0.5.sp,
        )
    }
}

/// Preserve the real localized tab label on narrow screens and large fonts:
/// three tabs when each label fits, two then one, or three stacked tabs.
/// The text itself remains accessible and is not truncated or split mid-word.
internal fun modeSelectorColumns(availableWidthDp: Float, maxLabelWidthDp: Float): Int {
    val paddedLabel = maxLabelWidthDp + 20f // 12dp text inset + safety
    return when {
        (availableWidthDp - 12f) / 3f >= paddedLabel -> 3
        (availableWidthDp - 6f) / 2f >= paddedLabel -> 2
        else -> 1
    }
}

@Composable
fun ModeSelector(
    mode: ToolMode,
    enabled: Boolean,
    onModeChange: (ToolMode) -> Unit,
    modifier: Modifier = Modifier,
) {
    val sizeLabel = stringResource(R.string.file_size)
    val pixelsLabel = stringResource(R.string.dimensions)
    val passportLabel = stringResource(R.string.passport)
    val textMeasurer = rememberTextMeasurer()
    val density = LocalDensity.current
    val captions = listOf(sizeLabel, pixelsLabel, passportLabel)
    BoxWithConstraints(modifier = modifier.fillMaxWidth()) {
        val requiredLabelWidth = with(density) {
            captions.maxOf { caption ->
                textMeasurer.measure(
                    text = AnnotatedString(caption),
                    style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.SemiBold),
                    maxLines = 1,
                ).size.width.toDp().value
            }
        }
        val columnCount = modeSelectorColumns(maxWidth.value, requiredLabelWidth)

        @Composable
        fun tab(label: String, option: ToolMode, modifier: Modifier) {
            ModeButton(
                label = label,
                selected = mode == option,
                enabled = enabled,
                onClick = { onModeChange(option) },
                modifier = modifier,
            )
        }

        when (columnCount) {
            3 -> Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                tab(sizeLabel, ToolMode.FILE_SIZE, Modifier.weight(1f))
                tab(pixelsLabel, ToolMode.PIXELS, Modifier.weight(1f))
                tab(passportLabel, ToolMode.PASSPORT, Modifier.weight(1f))
            }
            2 -> Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    tab(sizeLabel, ToolMode.FILE_SIZE, Modifier.weight(1f))
                    tab(pixelsLabel, ToolMode.PIXELS, Modifier.weight(1f))
                }
                tab(passportLabel, ToolMode.PASSPORT, Modifier.fillMaxWidth())
            }
            else -> Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                tab(sizeLabel, ToolMode.FILE_SIZE, Modifier.fillMaxWidth())
                tab(pixelsLabel, ToolMode.PIXELS, Modifier.fillMaxWidth())
                tab(passportLabel, ToolMode.PASSPORT, Modifier.fillMaxWidth())
            }
        }
    }
}

@Composable
private fun ModeButton(
    label: String,
    selected: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val background = if (selected) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.surface
    }
    val foreground = if (selected) {
        MaterialTheme.colorScheme.onPrimary
    } else {
        MaterialTheme.colorScheme.onSurface
    }
    val border = if (selected) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.outlineVariant
    }

    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .heightIn(min = 56.dp)
            .semantics {
                this.selected = selected
                role = Role.Tab
            },
        shape = RoundedCornerShape(14.dp),
        color = background,
        contentColor = foreground,
        border = BorderStroke(1.dp, border),
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = label,
                modifier = Modifier.padding(horizontal = 6.dp, vertical = 8.dp),
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
fun BrandCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
        ),
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant,
        ),
        content = {
            Column(
                modifier = Modifier.padding(14.dp),
                content = { content() },
            )
        },
    )
}

@Composable
fun BrandPrimaryButton(
    text: String,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    busy: Boolean = false,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp),
        shape = RoundedCornerShape(16.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary,
            disabledContainerColor = MaterialTheme.colorScheme.surface,
            disabledContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
        ),
    ) {
        if (busy) {
            CircularProgressIndicator(
                modifier = Modifier.height(22.dp),
                strokeWidth = 2.dp,
                color = MaterialTheme.colorScheme.onPrimary,
            )
        } else {
            Text(
                text = text,
                style = MaterialTheme.typography.labelLarge,
            )
        }
    }
}

@Composable
fun BrandSecondaryButton(
    text: String,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp),
        shape = RoundedCornerShape(16.dp),
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outline,
        ),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = MaterialTheme.colorScheme.onSurface,
        ),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
        )
    }
}

@Composable
fun BrandAccentText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.secondary,
) {
    Text(
        text = text,
        modifier = modifier,
        color = color,
        style = MaterialTheme.typography.labelMedium,
        fontWeight = FontWeight.Bold,
    )
}
