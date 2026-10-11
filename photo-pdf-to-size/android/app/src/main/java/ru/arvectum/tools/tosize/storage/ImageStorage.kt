package ru.arvectum.tools.tosize.storage

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import androidx.exifinterface.media.ExifInterface
import ru.arvectum.tools.tosize.ResultImage
import ru.arvectum.tools.tosize.SourceImage
import ru.arvectum.tools.tosize.UserVisibleException
import java.io.FileInputStream

class ImageStorage(private val context: Context) {
    private val resolver = context.contentResolver

    fun inspect(uri: Uri): SourceImage {
        var name = "image"
        var size = -1L
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (nameIndex >= 0) name = cursor.getString(nameIndex) ?: name
                    if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
                }
            }

        val mime = (resolver.getType(uri) ?: mimeFromName(name)).lowercase()
        if (mime !in SUPPORTED_MIME_TYPES) {
            throw UserVisibleException("Этот формат пока не поддерживается.")
        }
        if (mime == "image/webp" && isAnimatedWebP(uri)) {
            throw UserVisibleException("Анимированный WebP пока не поддерживается.")
        }

        if (size <= 0L) {
            size = resolver.openAssetFileDescriptor(uri, "r")?.use { it.length } ?: -1L
        }
        if (size <= 0L) size = countBytes(uri)

        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, options) }
        if (options.outWidth <= 0 || options.outHeight <= 0) {
            throw UserVisibleException("Не получилось открыть это изображение.")
        }

        val orientation = readOrientation(uri)
        val swap = orientation == ExifInterface.ORIENTATION_ROTATE_90 ||
            orientation == ExifInterface.ORIENTATION_ROTATE_270 ||
            orientation == ExifInterface.ORIENTATION_TRANSPOSE ||
            orientation == ExifInterface.ORIENTATION_TRANSVERSE

        return SourceImage(
            uri = uri,
            displayName = name,
            sizeBytes = size,
            width = if (swap) options.outHeight else options.outWidth,
            height = if (swap) options.outWidth else options.outHeight,
            mimeType = mime,
        )
    }

    fun save(result: ResultImage, destination: Uri) {
        val output = resolver.openOutputStream(destination, "w")
            ?: throw UserVisibleException("Не получилось сохранить файл.")
        output.use { out ->
            if (result.outputFile != null) {
                FileInputStream(result.outputFile).use { it.copyTo(out) }
            } else {
                resolver.openInputStream(result.source.uri)?.use { it.copyTo(out) }
                    ?: throw UserVisibleException("Не получилось прочитать исходный файл.")
            }
        }
    }

    fun shareIntent(result: ResultImage): Intent {
        val uri = if (result.outputFile != null) {
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                result.outputFile,
            )
        } else {
            result.source.uri
        }
        val type = if (result.outputFile != null) "image/jpeg" else result.source.mimeType
        return Intent(Intent.ACTION_SEND).apply {
            this.type = type
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri("image", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun readOrientation(uri: Uri): Int = try {
        resolver.openInputStream(uri)?.use {
            ExifInterface(it).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } ?: ExifInterface.ORIENTATION_NORMAL
    } catch (_: Exception) {
        ExifInterface.ORIENTATION_NORMAL
    }

    private fun countBytes(uri: Uri): Long {
        var total = 0L
        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
        resolver.openInputStream(uri)?.use { input ->
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                total += count
            }
        } ?: throw UserVisibleException("Не получилось прочитать этот файл.")
        return total
    }

    private fun isAnimatedWebP(uri: Uri): Boolean {
        val needle = byteArrayOf('A'.code.toByte(), 'N'.code.toByte(), 'I'.code.toByte(), 'M'.code.toByte())
        val buffer = ByteArray(512 * 1024)
        val read = resolver.openInputStream(uri)?.use { input ->
            var offset = 0
            while (offset < buffer.size) {
                val count = input.read(buffer, offset, buffer.size - offset)
                if (count < 0) break
                offset += count
            }
            offset
        } ?: return false
        for (i in 0..(read - needle.size).coerceAtLeast(-1)) {
            if (needle.indices.all { j -> buffer[i + j] == needle[j] }) return true
        }
        return false
    }

    private fun mimeFromName(name: String): String = when (name.substringAfterLast('.', "").lowercase()) {
        "jpg", "jpeg" -> "image/jpeg"
        "png" -> "image/png"
        "webp" -> "image/webp"
        else -> "application/octet-stream"
    }

    companion object {
        private val SUPPORTED_MIME_TYPES = setOf("image/jpeg", "image/png", "image/webp")
    }
}
