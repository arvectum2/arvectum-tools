package ru.arvectum.tools.tosize.ui

import android.graphics.Bitmap
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
}

@Composable
private fun LoadingCrop() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        CircularProgressIndicator()
        Spacer(Modifier.height(16.dp))
        Text("Готовим фото…")
    }
}

@Composable
private fun CropLoadError(onCancel: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .padding(20.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = "Не получилось открыть фото для кадрирования.",
            style = MaterialTheme.typography.titleMedium,
        )
        Spacer(Modifier.height(20.dp))
        OutlinedButton(
            onClick = onCancel,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Назад")
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
            .systemBarsPadding()
            .padding(horizontal = 20.dp, vertical = 20.dp),
    ) {
        Text(
            text = "На паспорт",
            style = MaterialTheme.typography.headlineSmall,
        )
        Text(
            text = "Для заявления на Госуслугах",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        Spacer(Modifier.height(20.dp))
        Text(
            text = "Расположите фото в рамке 35×45",
            style = MaterialTheme.typography.titleMedium,
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = "Перетаскивайте фото и увеличивайте двумя пальцами. В файл попадёт только содержимое рамки.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(16.dp))

        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(
                    CompressionEngine.PASSPORT_WIDTH_PX.toFloat() /
                        CompressionEngine.PASSPORT_HEIGHT_PX,
                )
                .border(
                    width = 2.dp,
                    color = MaterialTheme.colorScheme.primary,
                    shape = RoundedCornerShape(16.dp),
                )
                .onSizeChanged { viewport = it }
                .pointerInput(bitmap, viewport) {
                    detectTransformGestures { _, pan, gestureZoom, _ ->
                        if (size.width == 0 || size.height == 0) return@detectTransformGestures

                        val newZoom = (zoom * gestureZoom).coerceIn(1f, MAX_ZOOM)
                        val baseScale = max(
                            size.width / bitmap.width.toFloat(),
                            size.height / bitmap.height.toFloat(),
                        )
                        val displayWidth = bitmap.width * baseScale * newZoom
                        val displayHeight = bitmap.height * baseScale * newZoom
                        val maxX = max(0f, (displayWidth - size.width) / 2f)
                        val maxY = max(0f, (displayHeight - size.height) / 2f)

                        offset = Offset(
                            x = (offset.x + pan.x).coerceIn(-maxX, maxX),
                            y = (offset.y + pan.y).coerceIn(-maxY, maxY),
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
            val left = (size.width - displayWidth) / 2f + offset.x
            val top = (size.height - displayHeight) / 2f + offset.y

            drawImage(
                image = image,
                dstOffset = IntOffset(left.roundToInt(), top.roundToInt()),
                dstSize = IntSize(
                    displayWidth.roundToInt(),
                    displayHeight.roundToInt(),
                ),
                filterQuality = FilterQuality.High,
            )
        }

        Spacer(Modifier.height(12.dp))
        Text(
            text = "Итог: 620×797 px · 450 DPI · JPEG",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(20.dp))

        Button(
            onClick = {
                if (viewport.width > 0 && viewport.height > 0) {
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
                }
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Сделать фото")
        }

        Spacer(Modifier.height(8.dp))
        OutlinedButton(
            onClick = onCancel,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Отмена")
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
    val leftOnScreen = (viewportWidth - displayWidth) / 2f + offset.x
    val topOnScreen = (viewportHeight - displayHeight) / 2f + offset.y

    val sourceLeft = (-leftOnScreen / totalScale).coerceIn(0f, bitmapWidth.toFloat())
    val sourceTop = (-topOnScreen / totalScale).coerceIn(0f, bitmapHeight.toFloat())
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
