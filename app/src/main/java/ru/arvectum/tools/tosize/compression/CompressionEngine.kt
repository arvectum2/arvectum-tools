package ru.arvectum.tools.tosize.compression

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import androidx.core.graphics.createBitmap
import androidx.core.graphics.scale
import androidx.exifinterface.media.ExifInterface
import ru.arvectum.tools.tosize.NormalizedCropRect
import ru.arvectum.tools.tosize.SourceImage
import ru.arvectum.tools.tosize.UserVisibleException
import ru.arvectum.tools.tosize.calculateLongSideDimensions
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

data class CompressionOutput(
    val file: File,
    val sizeBytes: Long,
    val width: Int,
    val height: Int,
)

class CompressionEngine(private val context: Context) {
    fun compressByBytes(
        source: SourceImage,
        requestedMaximumBytes: Long,
    ): CompressionOutput = guarded {
        requireTargetBytes(requestedMaximumBytes)
        compressByBytesInternal(source, requestedMaximumBytes)
    }

    fun resizeLongSide(
        source: SourceImage,
        targetLongSide: Int,
    ): CompressionOutput = guarded {
        if (targetLongSide <= 0) {
            throw UserVisibleException("Укажите размер длинной стороны.")
        }

        var working = ImageDecoder.decodeOriented(context, source, MAX_DECODE_PIXELS)
        try {
            working = flattenIfNeeded(working)
            val target = calculateLongSideDimensions(
                working.width,
                working.height,
                targetLongSide,
            )
            val scaled = working.scale(target.width, target.height, filter = true)
            if (scaled !== working) working.recycle()
            working = scaled

            val bytes = encode(working, PIXEL_MODE_QUALITY)
            val file = createResultFile(source)
            file.writeBytes(bytes)
            CompressionOutput(
                file = file,
                sizeBytes = file.length(),
                width = working.width,
                height = working.height,
            )
        } finally {
            if (!working.isRecycled) working.recycle()
        }
    }

    fun preparePassport(
        source: SourceImage,
        crop: NormalizedCropRect,
    ): CompressionOutput = guarded {
        var working = ImageDecoder.decodeOriented(context, source, MAX_DECODE_PIXELS)
        try {
            val left = (crop.left.coerceIn(0f, 1f) * working.width)
                .roundToInt()
                .coerceIn(0, working.width - 1)
            val top = (crop.top.coerceIn(0f, 1f) * working.height)
                .roundToInt()
                .coerceIn(0, working.height - 1)
            val right = (crop.right.coerceIn(0f, 1f) * working.width)
                .roundToInt()
                .coerceIn(left + 1, working.width)
            val bottom = (crop.bottom.coerceIn(0f, 1f) * working.height)
                .roundToInt()
                .coerceIn(top + 1, working.height)

            var cropped = Bitmap.createBitmap(
                working,
                left,
                top,
                right - left,
                bottom - top,
            )
            if (cropped !== working) working.recycle()
            working = cropped

            working = flattenIfNeeded(working)
            val scaled = working.scale(
                PASSPORT_WIDTH_PX,
                PASSPORT_HEIGHT_PX,
                filter = true,
            )
            if (scaled !== working) working.recycle()
            working = scaled

            var bytes = encodeWithinMaximum(
                bitmap = working,
                maximumBytes = PASSPORT_MAX_BYTES,
                minQuality = PASSPORT_MIN_QUALITY,
                maxQuality = PASSPORT_MAX_QUALITY,
            )
            if (bytes.size < PASSPORT_MIN_BYTES) {
                bytes = encode(working, 100)
            }

            val file = createResultFile(source)
            file.writeBytes(bytes)
            writeDpiMetadata(file, PASSPORT_DPI)

            val finalSize = file.length()
            if (finalSize !in PASSPORT_MIN_BYTES.toLong()..PASSPORT_MAX_BYTES.toLong()) {
                file.delete()
                throw UserVisibleException(
                    "Не получилось уложить паспортное фото в допустимый размер файла.",
                )
            }

            CompressionOutput(
                file = file,
                sizeBytes = finalSize,
                width = PASSPORT_WIDTH_PX,
                height = PASSPORT_HEIGHT_PX,
            )
        } finally {
            if (!working.isRecycled) working.recycle()
        }
    }

    private fun compressByBytesInternal(
        source: SourceImage,
        requestedMaximumBytes: Long,
    ): CompressionOutput {
        val internalTarget = max(1L, (requestedMaximumBytes * TARGET_HEADROOM).toLong())
        var working = ImageDecoder.decodeOriented(context, source, MAX_DECODE_PIXELS)

        try {
            working = flattenIfNeeded(working)

            repeat(MAX_RESIZE_ROUNDS + 1) { round ->
                val search = searchBestQuality(working, internalTarget)
                search.bestBytes?.let { bytes ->
                    val file = createResultFile(source)
                    file.writeBytes(bytes)
                    if (file.length() > requestedMaximumBytes) {
                        file.delete()
                        throw UserVisibleException(
                            "Не удалось надёжно уложить файл в заданный размер.",
                        )
                    }
                    return CompressionOutput(
                        file = file,
                        sizeBytes = file.length(),
                        width = working.width,
                        height = working.height,
                    )
                }

                if (round == MAX_RESIZE_ROUNDS) return@repeat
                val shortSide = min(working.width, working.height)
                if (shortSide <= MIN_SHORT_SIDE) return@repeat

                val ratio = sqrt(
                    internalTarget.toDouble() / search.minimumQualityBytes.toDouble(),
                ) * 0.92
                var scale = ratio.coerceIn(0.50, 0.88)
                if ((shortSide * scale).toInt() < MIN_SHORT_SIDE) {
                    scale = MIN_SHORT_SIDE.toDouble() / shortSide.toDouble()
                }
                if (scale >= 0.99) scale = 0.88

                val newWidth = max(1, (working.width * scale).toInt())
                val newHeight = max(1, (working.height * scale).toInt())
                val scaled = working.scale(newWidth, newHeight, filter = true)
                if (scaled !== working) working.recycle()
                working = scaled
            }

            throw UserVisibleException(
                "До такого размера уменьшить изображение без серьёзной потери качества не удалось.",
            )
        } finally {
            if (!working.isRecycled) working.recycle()
        }
    }

    private fun searchBestQuality(
        bitmap: Bitmap,
        targetBytes: Long,
    ): SearchResult {
        val minimum = encode(bitmap, MIN_JPEG_QUALITY)
        if (minimum.size > targetBytes) {
            return SearchResult(
                bestBytes = null,
                minimumQualityBytes = minimum.size,
            )
        }

        var best = minimum
        var low = MIN_JPEG_QUALITY + 1
        var high = MAX_JPEG_QUALITY
        while (low <= high) {
            val quality = (low + high) / 2
            val encoded = encode(bitmap, quality)
            if (encoded.size <= targetBytes) {
                best = encoded
                low = quality + 1
            } else {
                high = quality - 1
            }
        }
        return SearchResult(bestBytes = best, minimumQualityBytes = minimum.size)
    }

    private fun encodeWithinMaximum(
        bitmap: Bitmap,
        maximumBytes: Int,
        minQuality: Int,
        maxQuality: Int,
    ): ByteArray {
        val highest = encode(bitmap, maxQuality)
        if (highest.size <= maximumBytes) return highest

        val lowest = encode(bitmap, minQuality)
        if (lowest.size > maximumBytes) {
            throw UserVisibleException("Не получилось уложить изображение в допустимый размер.")
        }

        var best = lowest
        var low = minQuality + 1
        var high = maxQuality - 1
        while (low <= high) {
            val quality = (low + high) / 2
            val encoded = encode(bitmap, quality)
            if (encoded.size <= maximumBytes) {
                best = encoded
                low = quality + 1
            } else {
                high = quality - 1
            }
        }
        return best
    }

    private fun encode(bitmap: Bitmap, quality: Int): ByteArray {
        val stream = ByteArrayOutputStream()
        if (!bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)) {
            throw UserVisibleException("Не получилось создать JPG.")
        }
        return stream.toByteArray()
    }

    private fun flattenIfNeeded(bitmap: Bitmap): Bitmap {
        if (!bitmap.hasAlpha()) return bitmap
        val flattened = createBitmap(
            bitmap.width,
            bitmap.height,
            Bitmap.Config.ARGB_8888,
        )
        Canvas(flattened).apply {
            drawColor(Color.WHITE)
            drawBitmap(bitmap, 0f, 0f, null)
        }
        flattened.setHasAlpha(false)
        if (flattened !== bitmap) bitmap.recycle()
        return flattened
    }

    private fun writeDpiMetadata(file: File, dpi: Int) {
        ExifInterface(file).apply {
            setAttribute(ExifInterface.TAG_X_RESOLUTION, "$dpi/1")
            setAttribute(ExifInterface.TAG_Y_RESOLUTION, "$dpi/1")
            setAttribute(ExifInterface.TAG_RESOLUTION_UNIT, "2")
            saveAttributes()
        }
    }

    private fun requireTargetBytes(bytes: Long) {
        if (bytes <= 0L) {
            throw UserVisibleException("Укажите допустимый размер файла.")
        }
    }

    private fun createResultFile(source: SourceImage): File {
        val directory = File(context.cacheDir, "results").apply { mkdirs() }
        directory.listFiles()?.forEach { old ->
            if (System.currentTimeMillis() - old.lastModified() > CACHE_MAX_AGE_MS) {
                old.delete()
            }
        }
        val base = source.displayName.substringBeforeLast('.')
            .replace(Regex("[^\\p{L}\\p{N}_-]+"), "-")
            .trim('-')
            .ifBlank { "image" }
            .take(48)
        return File(directory, "$base-${System.currentTimeMillis()}.jpg")
    }

    private inline fun <T> guarded(block: () -> T): T {
        return try {
            block()
        } catch (error: UserVisibleException) {
            throw error
        } catch (_: OutOfMemoryError) {
            throw UserVisibleException(
                "Изображение слишком большое для обработки на этом устройстве.",
            )
        } catch (_: Exception) {
            throw UserVisibleException("Не получилось обработать это изображение.")
        }
    }

    private data class SearchResult(
        val bestBytes: ByteArray?,
        val minimumQualityBytes: Int,
    )

    companion object {
        const val PASSPORT_WIDTH_PX = 620
        const val PASSPORT_HEIGHT_PX = 797
        const val PASSPORT_DPI = 450

        private const val PASSPORT_MIN_BYTES = 10_000
        private const val PASSPORT_MAX_BYTES = 5_000_000
        private const val PASSPORT_MIN_QUALITY = 55
        private const val PASSPORT_MAX_QUALITY = 95
        private const val PIXEL_MODE_QUALITY = 95

        private const val MIN_JPEG_QUALITY = 35
        private const val MAX_JPEG_QUALITY = 95
        private const val MIN_SHORT_SIDE = 480
        private const val MAX_RESIZE_ROUNDS = 8
        private const val MAX_DECODE_PIXELS = 24_000_000L
        private const val TARGET_HEADROOM = 0.985
        private const val CACHE_MAX_AGE_MS = 24L * 60L * 60L * 1000L
    }
}
