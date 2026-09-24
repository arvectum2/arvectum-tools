package ru.arvectum.tools.tosize.compression

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import androidx.core.graphics.createBitmap
import androidx.core.graphics.scale
import androidx.exifinterface.media.ExifInterface
import ru.arvectum.tools.tosize.SourceImage
import ru.arvectum.tools.tosize.UserVisibleException
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

data class CompressionOutput(
    val file: File,
    val sizeBytes: Long,
)

class CompressionEngine(private val context: Context) {
    private val resolver = context.contentResolver

    fun compress(source: SourceImage, requestedMaximumBytes: Long): CompressionOutput {
        if (requestedMaximumBytes <= 0L) {
            throw UserVisibleException("Укажите допустимый размер файла.")
        }

        return try {
            compressInternal(source, requestedMaximumBytes)
        } catch (error: UserVisibleException) {
            throw error
        } catch (_: OutOfMemoryError) {
            throw UserVisibleException("Изображение слишком большое для обработки на этом устройстве.")
        } catch (_: Exception) {
            throw UserVisibleException("Не получилось уменьшить это изображение.")
        }
    }

    private fun compressInternal(source: SourceImage, requestedMaximumBytes: Long): CompressionOutput {
        val internalTarget = max(1L, (requestedMaximumBytes * TARGET_HEADROOM).toLong())
        var working = decodeOrientedBitmap(source)

        try {
            if (working.hasAlpha()) {
                val flattened = flattenOnWhite(working)
                if (flattened !== working) working.recycle()
                working = flattened
            }

            repeat(MAX_RESIZE_ROUNDS + 1) { round ->
                val search = searchBestQuality(working, internalTarget)
                search.bestBytes?.let { bytes ->
                    val file = createResultFile(source)
                    file.writeBytes(bytes)
                    if (file.length() > requestedMaximumBytes) {
                        file.delete()
                        throw UserVisibleException("Не удалось надёжно уложить файл в заданный размер.")
                    }
                    return CompressionOutput(file, file.length())
                }

                if (round == MAX_RESIZE_ROUNDS) return@repeat
                val shortSide = min(working.width, working.height)
                if (shortSide <= MIN_SHORT_SIDE) return@repeat

                val ratio = sqrt(internalTarget.toDouble() / search.minimumQualityBytes.toDouble()) * 0.92
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

    private fun searchBestQuality(bitmap: Bitmap, targetBytes: Long): SearchResult {
        val minimum = encode(bitmap, MIN_JPEG_QUALITY)
        if (minimum.size > targetBytes) {
            return SearchResult(bestBytes = null, minimumQualityBytes = minimum.size)
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

    private fun encode(bitmap: Bitmap, quality: Int): ByteArray {
        val stream = ByteArrayOutputStream()
        if (!bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)) {
            throw UserVisibleException("Не получилось создать JPG.")
        }
        return stream.toByteArray()
    }

    private fun decodeOrientedBitmap(source: SourceImage): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(source.uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            ?: throw UserVisibleException("Не получилось прочитать исходный файл.")

        var sample = 1
        while (
            bounds.outWidth > 0 &&
            bounds.outHeight > 0 &&
            (bounds.outWidth.toLong() / sample) * (bounds.outHeight.toLong() / sample) > MAX_DECODE_PIXELS
        ) {
            sample *= 2
        }

        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val decoded = resolver.openInputStream(source.uri)?.use {
            BitmapFactory.decodeStream(it, null, options)
        } ?: throw UserVisibleException("Не получилось открыть это изображение.")

        val matrix = orientationMatrix(readOrientation(source))
        if (matrix.isIdentity) return decoded

        val oriented = Bitmap.createBitmap(
            decoded,
            0,
            0,
            decoded.width,
            decoded.height,
            matrix,
            true,
        )
        if (oriented !== decoded) decoded.recycle()
        return oriented
    }

    private fun readOrientation(source: SourceImage): Int = try {
        resolver.openInputStream(source.uri)?.use {
            ExifInterface(it).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } ?: ExifInterface.ORIENTATION_NORMAL
    } catch (_: Exception) {
        ExifInterface.ORIENTATION_NORMAL
    }

    private fun orientationMatrix(orientation: Int): Matrix = Matrix().apply {
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
                setRotate(180f)
                postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                setRotate(90f)
                postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                setRotate(-90f)
                postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> setRotate(-90f)
        }
    }

    private fun flattenOnWhite(bitmap: Bitmap): Bitmap {
        val output = createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        Canvas(output).apply {
            drawColor(Color.WHITE)
            drawBitmap(bitmap, 0f, 0f, null)
        }
        output.setHasAlpha(false)
        return output
    }

    private fun createResultFile(source: SourceImage): File {
        val directory = File(context.cacheDir, "results").apply { mkdirs() }
        directory.listFiles()?.forEach { old ->
            if (System.currentTimeMillis() - old.lastModified() > CACHE_MAX_AGE_MS) old.delete()
        }
        val base = source.displayName.substringBeforeLast('.')
            .replace(Regex("[^\\p{L}\\p{N}_-]+"), "-")
            .trim('-')
            .ifBlank { "image" }
            .take(48)
        return File(directory, "${base}-${System.currentTimeMillis()}.jpg")
    }

    private data class SearchResult(
        val bestBytes: ByteArray?,
        val minimumQualityBytes: Int,
    )

    companion object {
        private const val MIN_JPEG_QUALITY = 35
        private const val MAX_JPEG_QUALITY = 95
        private const val MIN_SHORT_SIDE = 480
        private const val MAX_RESIZE_ROUNDS = 8
        private const val MAX_DECODE_PIXELS = 24_000_000L
        private const val TARGET_HEADROOM = 0.985
        private const val CACHE_MAX_AGE_MS = 24L * 60L * 60L * 1000L
    }
}
