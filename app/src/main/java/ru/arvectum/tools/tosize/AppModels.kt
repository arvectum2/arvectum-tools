package ru.arvectum.tools.tosize

import android.net.Uri
import java.io.File

data class SourceImage(
    val uri: Uri,
    val displayName: String,
    val sizeBytes: Long,
    val width: Int,
    val height: Int,
    val mimeType: String,
)

data class ResultImage(
    val source: SourceImage,
    val outputFile: File?,
    val outputSizeBytes: Long,
    val targetBytes: Long,
    val alreadyFit: Boolean,
)

enum class SizeUnit(val multiplier: Long, val label: String) {
    KB(1_000L, "КБ"),
    MB(1_000_000L, "МБ"),
}

data class AppUiState(
    val source: SourceImage? = null,
    val targetBytes: Long? = 5_000_000L,
    val isCustomTarget: Boolean = false,
    val customValue: String = "",
    val customUnit: SizeUnit = SizeUnit.KB,
    val isWorking: Boolean = false,
    val result: ResultImage? = null,
    val error: String? = null,
    val saved: Boolean = false,
)

class UserVisibleException(message: String) : Exception(message)
