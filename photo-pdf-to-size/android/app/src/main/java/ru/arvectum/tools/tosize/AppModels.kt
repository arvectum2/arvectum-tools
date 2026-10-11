package ru.arvectum.tools.tosize

import android.net.Uri
import java.io.File
import kotlin.math.roundToInt

enum class ToolMode {
    FILE_SIZE,
    PIXELS,
    PASSPORT,
}

data class SourceImage(
    val uri: Uri,
    val displayName: String,
    val sizeBytes: Long,
    val width: Int,
    val height: Int,
    val mimeType: String,
)

data class ImageDimensions(
    val width: Int,
    val height: Int,
)

data class NormalizedCropRect(
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
)

data class ResultImage(
    val source: SourceImage,
    val outputFile: File?,
    val outputSizeBytes: Long,
    val outputWidth: Int,
    val outputHeight: Int,
    val mode: ToolMode,
    val targetBytes: Long? = null,
    val targetLongSide: Int? = null,
    val alreadyFit: Boolean = false,
)

enum class SizeUnit(val multiplier: Long, val label: String) {
    KB(1_000L, "КБ"),
    MB(1_000_000L, "МБ"),
}

data class AppUiState(
    val mode: ToolMode = ToolMode.FILE_SIZE,
    val source: SourceImage? = null,
    val targetBytes: Long? = 5_000_000L,
    val isCustomTarget: Boolean = false,
    val customValue: String = "",
    val customUnit: SizeUnit = SizeUnit.KB,
    val targetLongSide: Int? = 600,
    val isCustomPixels: Boolean = false,
    val customPixelsValue: String = "",
    val passportCropOpen: Boolean = false,
    val isWorking: Boolean = false,
    val result: ResultImage? = null,
    val error: String? = null,
    val saved: Boolean = false,
)

fun calculateLongSideDimensions(
    width: Int,
    height: Int,
    targetLongSide: Int,
): ImageDimensions {
    require(width > 0 && height > 0 && targetLongSide > 0)
    return if (width >= height) {
        ImageDimensions(
            width = targetLongSide,
            height = (height.toDouble() * targetLongSide / width).roundToInt().coerceAtLeast(1),
        )
    } else {
        ImageDimensions(
            width = (width.toDouble() * targetLongSide / height).roundToInt().coerceAtLeast(1),
            height = targetLongSide,
        )
    }
}

class UserVisibleException(message: String) : Exception(message)
