package ru.arvectum.tools.tosize.compression

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import ru.arvectum.tools.tosize.SourceImage
import ru.arvectum.tools.tosize.UserVisibleException

object ImageDecoder {
    fun decodeOriented(
        context: Context,
        source: SourceImage,
        maxPixels: Long,
    ): Bitmap {
        val resolver = context.contentResolver
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        val boundsStream = resolver.openInputStream(source.uri)
            ?: throw UserVisibleException("Не получилось прочитать исходный файл.")
        boundsStream.use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            throw UserVisibleException("Не получилось определить размер изображения.")
        }

        var sample = 1
        while (
            (bounds.outWidth.toLong() / sample) *
                (bounds.outHeight.toLong() / sample) > maxPixels
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

        val matrix = orientationMatrix(readOrientation(context, source))
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

    private fun readOrientation(context: Context, source: SourceImage): Int = try {
        context.contentResolver.openInputStream(source.uri)?.use {
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
}
