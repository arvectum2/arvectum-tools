package ru.arvectum.tools.tosize.ui

import android.graphics.Bitmap
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import ru.arvectum.tools.tosize.NormalizedCropRect
import ru.arvectum.tools.tosize.SourceImage
import ru.arvectum.tools.tosize.compression.CompressionEngine
import ru.arvectum.tools.tosize.compression.ImageDecoder
import kotlin.math.max
import kotlin.math.roundToInt

@Composable
fun PassportCropScreen(
    source: SourceImage,
    onCancel: () -> Unit,
    onConfirm: (NormalizedCropRect) -> Unit,
) {
    val context = LocalContext.current
    val previewResult by produceState<Result<Bitmap>?>(null, source.uri) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                ImageDecoder.decodeOriented(
                    context = context,
                    source = source,
                    maxPixels = PREVIEW_MAX_PIXELS,
                )
            }
        }
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
                    top = 8.dp,
                ),
            ) {
                BrandHeader()
                Spacer(Modifier.height(8.dp))
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) {
                when {
                    previewResult == null -> LoadingCrop()
                    previewResult?.isFailure == true -> CropLoadError(onCancel)
                    else -> CropEditor(
                        bitmap = previewResult!!.getOrThrow(),
                        onCancel = onCancel,
                        onConfirm = onConfirm,
                    )
                }
            }

            BrandFooter(
                modifier = Modifier.padding(horizontal = 18.dp),
            )
        }
    }
}

@Composable
private fun LoadingCrop() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        CircularProgressIndicator(
            color = MaterialTheme.colorScheme.primary,
        )
        Spacer(Modifier.height(14.dp))
        Text(
            text = "Готовим фото…",
            color = MaterialTheme.colorScheme.onBackground,
        )
    }
}

@Composable
private fun CropLoadError(onCancel: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 18.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        BrandCard {
            BrandAccentText("НА ПАСПОРТ")
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Не получилось открыть фото для кадрирования.",
                style = MaterialTheme.typography.titleMedium,
            )
            Spacer(Modifier.height(18.dp))
            BrandSecondaryButton(
                text = "Назад",
                enabled = true,
                onClick = onCancel,
            )
        }
    }
}

@Composable
private fun CropEditor(
    bitmap: Bitmap,
    onCancel: () -> Unit,
    onConfirm: (NormalizedCropRect) -> Unit,
) {
    var zoom by remember(bitmap) { mutableFloatStateOf(1f) }
    var offset by remember(bitmap) { mutableStateOf(Offset.Zero) }
    var viewport by remember { mutableStateOf(IntSize.Zero) }
    val image = remember(bitmap) { bitmap.asImageBitmap() }

    DisposableEffect(bitmap) {
        onDispose {
            if (!bitmap.isRecycled) bitmap.recycle()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 14.dp)
            .padding(bottom = 4.dp),
    ) {
        BrandCard(modifier = Modifier.fillMaxSize()) {
            BrandAccentText("НА ПАСПОРТ")
            Spacer(Modifier.height(4.dp))
            Text(
                text = "Подогнать фото под 35×45",
                style = MaterialTheme.typography.titleMedium,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = "Перемещайте фото и масштабируйте двумя пальцами.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(8.dp))

            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                Surface(
                    modifier = Modifier
                        .fillMaxHeight()
                        .aspectRatio(
                            CompressionEngine.PASSPORT_WIDTH_PX.toFloat() /
                                CompressionEngine.PASSPORT_HEIGHT_PX,
                            matchHeightConstraintsFirst = true,
                        ),
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.background,
                    border = BorderStroke(
                        2.dp,
                        MaterialTheme.colorScheme.primary,
                    ),
                ) {
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .onSizeChanged { viewport = it }
                            .pointerInput(bitmap, viewport) {
                            detectTransformGestures { _, pan, gestureZoom, _ ->
                                if (size.width == 0 || size.height == 0) {
                                    return@detectTransformGestures
                                }

                                val newZoom = (zoom * gestureZoom)
                                    .coerceIn(1f, MAX_ZOOM)
                                val baseScale = max(
                                    size.width / bitmap.width.toFloat(),
                                    size.height / bitmap.height.toFloat(),
                                )
                                val displayWidth =
                                    bitmap.width * baseScale * newZoom
                                val displayHeight =
                                    bitmap.height * baseScale * newZoom
                                val maxX =
                                    max(0f, (displayWidth - size.width) / 2f)
                                val maxY =
                                    max(0f, (displayHeight - size.height) / 2f)

                                offset = Offset(
                                    x = (offset.x + pan.x)
                                        .coerceIn(-maxX, maxX),
                                    y = (offset.y + pan.y)
                                        .coerceIn(-maxY, maxY),
                                )
                                zoom = newZoom
                            }
                        },
                ) {
                    val baseScale = max(
                        size.width / bitmap.width.toFloat(),
                        size.height / bitmap.height.toFloat(),
                    )
                    val totalScale = baseScale * zoom
                    val displayWidth = bitmap.width * totalScale
                    val displayHeight = bitmap.height * totalScale
                    val left =
                        (size.width - displayWidth) / 2f + offset.x
                    val top =
                        (size.height - displayHeight) / 2f + offset.y

                    drawImage(
                        image = image,
                        dstOffset = IntOffset(
                            left.roundToInt(),
                            top.roundToInt(),
                        ),
                        dstSize = IntSize(
                            displayWidth.roundToInt(),
                            displayHeight.roundToInt(),
                        ),
                        filterQuality = FilterQuality.High,
                    )
                    }
                }
            }

            Spacer(Modifier.height(8.dp))
            Text(
                text = "620×797 px · 450 DPI · JPEG",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(10.dp))

            BrandPrimaryButton(
                text = "Подготовить фото",
                enabled = viewport.width > 0 && viewport.height > 0,
                onClick = {
                    onConfirm(
                        calculateNormalizedCrop(
                            bitmapWidth = bitmap.width,
                            bitmapHeight = bitmap.height,
                            viewportWidth = viewport.width,
                            viewportHeight = viewport.height,
                            zoom = zoom,
                            offset = offset,
                        ),
                    )
                },
            )
            Spacer(Modifier.height(6.dp))
            BrandSecondaryButton(
                text = "Отмена",
                enabled = true,
                onClick = onCancel,
            )
        }
    }
}

fun calculateNormalizedCrop(
    bitmapWidth: Int,
    bitmapHeight: Int,
    viewportWidth: Int,
    viewportHeight: Int,
    zoom: Float,
    offset: Offset,
): NormalizedCropRect {
    val baseScale = max(
        viewportWidth / bitmapWidth.toFloat(),
        viewportHeight / bitmapHeight.toFloat(),
    )
    val totalScale = baseScale * zoom.coerceAtLeast(1f)
    val displayWidth = bitmapWidth * totalScale
    val displayHeight = bitmapHeight * totalScale
    val leftOnScreen =
        (viewportWidth - displayWidth) / 2f + offset.x
    val topOnScreen =
        (viewportHeight - displayHeight) / 2f + offset.y

    val sourceLeft = (-leftOnScreen / totalScale)
        .coerceIn(0f, bitmapWidth.toFloat())
    val sourceTop = (-topOnScreen / totalScale)
        .coerceIn(0f, bitmapHeight.toFloat())
    val sourceRight = ((viewportWidth - leftOnScreen) / totalScale)
        .coerceIn(0f, bitmapWidth.toFloat())
    val sourceBottom = ((viewportHeight - topOnScreen) / totalScale)
        .coerceIn(0f, bitmapHeight.toFloat())

    return NormalizedCropRect(
        left = sourceLeft / bitmapWidth,
        top = sourceTop / bitmapHeight,
        right = sourceRight / bitmapWidth,
        bottom = sourceBottom / bitmapHeight,
    )
}

private const val PREVIEW_MAX_PIXELS = 4_000_000L
private const val MAX_ZOOM = 5f
