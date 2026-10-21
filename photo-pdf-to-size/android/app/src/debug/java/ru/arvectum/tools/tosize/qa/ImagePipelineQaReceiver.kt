package ru.arvectum.tools.tosize.qa

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import androidx.core.content.FileProvider
import androidx.exifinterface.media.ExifInterface
import org.json.JSONObject
import ru.arvectum.tools.tosize.NormalizedCropRect
import ru.arvectum.tools.tosize.ResultImage
import ru.arvectum.tools.tosize.ToolMode
import ru.arvectum.tools.tosize.compression.CompressionEngine
import ru.arvectum.tools.tosize.storage.ImageStorage
import java.io.File
import java.util.Random

/**
 * Debug source-set ONLY. Tests real production image decoding/compression,
 * resizing, passport metadata, and save using deterministic synthetic pixels.
 * No gallery, iCloud, user files or private images are opened.
 * Restricted to DUMP-permission holder (adb shell), absent in Release.
 * System Photo Picker UX must be tested separately.
 */
class ImagePipelineQaReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        val pending = goAsync()
        Thread({
            val report = try {
                validatePipeline(context.applicationContext)
            } catch (failure: Throwable) {
                Log.e(TAG, "QA image pipeline failed", failure)
                JSONObject()
                    .put("status", "failed")
                    .put("error", failure.javaClass.simpleName)
                    .put("message", failure.message ?: "")
            }
            try {
                File(context.filesDir, REPORT).writeText(report.toString(2))
                Log.i(TAG, "QA image pipeline report: $report")
            } catch (writeFailure: Throwable) {
                Log.e(TAG, "Could not save QA report", writeFailure)
            } finally {
                pending.finish()
            }
        }, "arvectum-image-qa").start()
    }

    private fun validatePipeline(context: Context): JSONObject {
        val directory = File(context.cacheDir, "results").apply { mkdirs() }
        val generated = File(directory, "qa-synthetic-input.png")
        val bitmap = Bitmap.createBitmap(900, 700, Bitmap.Config.ARGB_8888)
        try {
            val random = Random(914441L)
            val pixels = IntArray(900 * 700) {
                Color.rgb(random.nextInt(256), random.nextInt(256), random.nextInt(256))
            }
            bitmap.setPixels(pixels, 0, 900, 0, 0, 900, 700)
            generated.outputStream().use { output ->
                check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, output))
            }
        } finally {
            bitmap.recycle()
        }

        val uri = FileProvider.getUriForFile(
            context, context.packageName + ".fileprovider", generated
        )
        val storage = ImageStorage(context)
        val engine = CompressionEngine(context)
        val source = storage.inspect(uri)
        check(source.width == 900 && source.height == 700)
        check(source.mimeType == "image/png")
        check(source.sizeBytes == generated.length())
        check(source.sizeBytes > MAXIMUM_COMPRESSED_BYTES)

        fun verifySave(result: ResultImage, filename: String) {
            val saved = File(directory, filename)
            val targetUri = FileProvider.getUriForFile(
                context, context.packageName + ".fileprovider", saved
            )
            storage.save(result, targetUri)
            check(saved.length() == result.outputSizeBytes)
            val decoded = BitmapFactory.decodeFile(saved.absolutePath)
                ?: error("Failed to decode saved JPEG: $filename")
            try {
                check(decoded.width == result.outputWidth)
                check(decoded.height == result.outputHeight)
            } finally {
                decoded.recycle()
            }
            check(saved.readBytes().take(2) == listOf(0xFF.toByte(), 0xD8.toByte()))
        }

        val compressed = engine.compressByBytes(source, MAXIMUM_COMPRESSED_BYTES)
        check(compressed.sizeBytes in 1..MAXIMUM_COMPRESSED_BYTES)
        check(compressed.width > 0 && compressed.height > 0)
        verifySave(
            ResultImage(
                source, compressed.file, compressed.sizeBytes,
                compressed.width, compressed.height, ToolMode.FILE_SIZE,
                targetBytes = MAXIMUM_COMPRESSED_BYTES
            ), "qa-saved-compressed.jpg"
        )

        val resized = engine.resizeLongSide(source, 400)
        check(resized.width == 400 && resized.height == 311)
        verifySave(
            ResultImage(
                source, resized.file, resized.sizeBytes,
                resized.width, resized.height, ToolMode.PIXELS, targetLongSide = 400
            ), "qa-saved-resized.jpg"
        )

        val passport = engine.preparePassport(
            source, NormalizedCropRect(0.198f, 0f, 0.802f, 1f)
        )
        check(passport.width == CompressionEngine.PASSPORT_WIDTH_PX)
        check(passport.height == CompressionEngine.PASSPORT_HEIGHT_PX)
        check(passport.sizeBytes in 10_000..5_000_000)
        val exif = ExifInterface(passport.file)
        val dpi = exif.getAttributeDouble(ExifInterface.TAG_X_RESOLUTION, 0.0)
        check(dpi in 449.5..450.5) { "Passport EXIF DPI: $dpi" }
        verifySave(
            ResultImage(
                source, passport.file, passport.sizeBytes,
                passport.width, passport.height, ToolMode.PASSPORT
            ), "qa-saved-passport.jpg"
        )
        return JSONObject()
            .put("status", "passed")
            .put("sourceWidth", source.width)
            .put("sourceHeight", source.height)
            .put("sourceBytes", source.sizeBytes)
            .put("compressedBytes", compressed.sizeBytes)
            .put("maximumBytes", MAXIMUM_COMPRESSED_BYTES)
            .put("resizedWidth", resized.width)
            .put("resizedHeight", resized.height)
            .put("passportWidth", passport.width)
            .put("passportHeight", passport.height)
            .put("passportDpi", dpi)
            .put("savedOutputs", 3)
    }

    private companion object {
        const val TAG = "ArvectumImagePipelineQa"
        const val ACTION = "ru.arvectum.tools.tosize.QA_IMAGE_PIPELINE"
        const val REPORT = "qa-image-pipeline.json"
        const val MAXIMUM_COMPRESSED_BYTES = 500_000L
    }
}
