package ru.arvectum.tools.tosize

import android.app.Application
import android.content.Intent
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import ru.arvectum.tools.tosize.compression.CompressionEngine
import ru.arvectum.tools.tosize.storage.ImageStorage
import kotlin.math.max
import kotlin.math.roundToLong

class MainViewModel(application: Application) : AndroidViewModel(application) {
    private val storage = ImageStorage(application)
    private val compressor = CompressionEngine(application)

    private val _state = MutableStateFlow(AppUiState())
    val state: StateFlow<AppUiState> = _state.asStateFlow()

    fun setMode(mode: ToolMode) {
        _state.update {
            it.copy(
                mode = mode,
                result = null,
                passportCropOpen = false,
                saved = false,
                error = null,
            )
        }
    }

    fun selectImage(uri: Uri) {
        _state.update {
            it.copy(
                isWorking = true,
                error = null,
                saved = false,
                result = null,
                passportCropOpen = false,
            )
        }
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val source = storage.inspect(uri)
                _state.update { current ->
                    current.copy(
                        source = source,
                        isWorking = false,
                        error = null,
                        saved = false,
                        result = null,
                    )
                }
            } catch (error: Exception) {
                _state.update {
                    it.copy(
                        source = null,
                        isWorking = false,
                        error = error.userMessage("Не получилось открыть этот файл."),
                    )
                }
            }
        }
    }

    fun setPreset(bytes: Long) {
        _state.update {
            it.copy(
                targetBytes = bytes,
                isCustomTarget = false,
                result = null,
                saved = false,
                error = null,
            )
        }
    }

    fun startCustomTarget() {
        _state.update {
            it.copy(
                isCustomTarget = true,
                customValue = "",
                targetBytes = null,
                result = null,
                saved = false,
            )
        }
    }

    fun setCustomValue(value: String) {
        val cleaned = value.filter { it.isDigit() || it == ',' || it == '.' }.take(10)
        _state.update { current ->
            current.copy(
                customValue = cleaned,
                targetBytes = parseCustomTarget(cleaned, current.customUnit),
                result = null,
                saved = false,
            )
        }
    }

    fun setCustomUnit(unit: SizeUnit) {
        _state.update { current ->
            current.copy(
                customUnit = unit,
                targetBytes = parseCustomTarget(current.customValue, unit),
                result = null,
                saved = false,
            )
        }
    }

    fun setPixelPreset(longSide: Int) {
        _state.update {
            it.copy(
                targetLongSide = longSide,
                isCustomPixels = false,
                result = null,
                saved = false,
                error = null,
            )
        }
    }

    fun startCustomPixels() {
        _state.update {
            it.copy(
                isCustomPixels = true,
                customPixelsValue = "",
                targetLongSide = null,
                result = null,
                saved = false,
            )
        }
    }

    fun setCustomPixels(value: String) {
        val cleaned = value.filter(Char::isDigit).take(5)
        _state.update {
            it.copy(
                customPixelsValue = cleaned,
                targetLongSide = cleaned.toIntOrNull()
                    ?.takeIf { px -> px in MIN_CUSTOM_PIXELS..MAX_CUSTOM_PIXELS },
                result = null,
                saved = false,
            )
        }
    }

    fun compressByBytes() {
        val snapshot = _state.value
        val source = snapshot.source ?: return
        val target = snapshot.targetBytes ?: return

        if (source.sizeBytes <= target) {
            _state.update {
                it.copy(
                    result = originalResult(
                        source = source,
                        mode = ToolMode.FILE_SIZE,
                        targetBytes = target,
                    ),
                    saved = false,
                )
            }
            return
        }

        runProcessing("Не получилось уменьшить это изображение.") {
            val output = compressor.compressByBytes(source, target)
            ResultImage(
                source = source,
                outputFile = output.file,
                outputSizeBytes = output.sizeBytes,
                outputWidth = output.width,
                outputHeight = output.height,
                mode = ToolMode.FILE_SIZE,
                targetBytes = target,
            )
        }
    }

    fun resizeByPixels() {
        val snapshot = _state.value
        val source = snapshot.source ?: return
        val target = snapshot.targetLongSide ?: return
        val sourceLongSide = max(source.width, source.height)

        if (sourceLongSide <= target) {
            _state.update {
                it.copy(
                    result = originalResult(
                        source = source,
                        mode = ToolMode.PIXELS,
                        targetLongSide = target,
                    ),
                    saved = false,
                )
            }
            return
        }

        runProcessing("Не получилось изменить размер изображения.") {
            val output = compressor.resizeLongSide(source, target)
            ResultImage(
                source = source,
                outputFile = output.file,
                outputSizeBytes = output.sizeBytes,
                outputWidth = output.width,
                outputHeight = output.height,
                mode = ToolMode.PIXELS,
                targetLongSide = target,
            )
        }
    }

    fun openPassportCrop() {
        if (_state.value.source == null) return
        _state.update {
            it.copy(
                passportCropOpen = true,
                error = null,
                saved = false,
            )
        }
    }

    fun closePassportCrop() {
        _state.update { it.copy(passportCropOpen = false) }
    }

    fun preparePassport(crop: NormalizedCropRect) {
        val source = _state.value.source ?: return
        _state.update { it.copy(passportCropOpen = false) }

        runProcessing("Не получилось подготовить фото на паспорт.") {
            val output = compressor.preparePassport(source, crop)
            ResultImage(
                source = source,
                outputFile = output.file,
                outputSizeBytes = output.sizeBytes,
                outputWidth = output.width,
                outputHeight = output.height,
                mode = ToolMode.PASSPORT,
            )
        }
    }

    fun saveTo(destination: Uri) {
        val result = currentResultForAction() ?: return
        _state.update { it.copy(isWorking = true, saved = false, error = null) }
        viewModelScope.launch(Dispatchers.IO) {
            try {
                storage.save(result, destination)
                _state.update { it.copy(isWorking = false, saved = true) }
            } catch (error: Exception) {
                _state.update {
                    it.copy(
                        isWorking = false,
                        error = error.userMessage("Не получилось сохранить файл."),
                    )
                }
            }
        }
    }

    fun shareIntent(): Intent? = currentResultForAction()?.let(storage::shareIntent)

    fun suggestedFileName(): String {
        val result = currentResultForAction() ?: return "image.jpg"
        if (result.outputFile == null) return result.source.displayName
        val base = result.source.displayName.substringBeforeLast('.').ifBlank { "image" }
        val suffix = when (result.mode) {
            ToolMode.FILE_SIZE -> "до-размера"
            ToolMode.PIXELS -> "по-пикселям"
            ToolMode.PASSPORT -> "на-паспорт"
        }
        return "$base-$suffix.jpg"
    }

    fun backToSelection() {
        _state.update {
            it.copy(
                result = null,
                passportCropOpen = false,
                saved = false,
                error = null,
            )
        }
    }

    fun reset() {
        val currentMode = _state.value.mode
        _state.value = AppUiState(mode = currentMode)
    }

    fun dismissError() {
        _state.update { it.copy(error = null) }
    }

    private fun currentResultForAction(): ResultImage? {
        val snapshot = _state.value
        snapshot.result?.let { return it }
        val source = snapshot.source ?: return null

        return when (snapshot.mode) {
            ToolMode.FILE_SIZE -> {
                val target = snapshot.targetBytes ?: return null
                if (source.sizeBytes <= target) {
                    originalResult(
                        source = source,
                        mode = ToolMode.FILE_SIZE,
                        targetBytes = target,
                    )
                } else {
                    null
                }
            }

            ToolMode.PIXELS -> {
                val target = snapshot.targetLongSide ?: return null
                if (max(source.width, source.height) <= target) {
                    originalResult(
                        source = source,
                        mode = ToolMode.PIXELS,
                        targetLongSide = target,
                    )
                } else {
                    null
                }
            }

            ToolMode.PASSPORT -> null
        }
    }

    private fun originalResult(
        source: SourceImage,
        mode: ToolMode,
        targetBytes: Long? = null,
        targetLongSide: Int? = null,
    ) = ResultImage(
        source = source,
        outputFile = null,
        outputSizeBytes = source.sizeBytes,
        outputWidth = source.width,
        outputHeight = source.height,
        mode = mode,
        targetBytes = targetBytes,
        targetLongSide = targetLongSide,
        alreadyFit = true,
    )

    private fun runProcessing(
        fallbackError: String,
        block: () -> ResultImage,
    ) {
        _state.update {
            it.copy(
                isWorking = true,
                error = null,
                saved = false,
                result = null,
            )
        }
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val result = block()
                _state.update {
                    it.copy(
                        isWorking = false,
                        result = result,
                    )
                }
            } catch (error: Exception) {
                _state.update {
                    it.copy(
                        isWorking = false,
                        error = error.userMessage(fallbackError),
                    )
                }
            }
        }
    }

    private fun parseCustomTarget(value: String, unit: SizeUnit): Long? {
        val numeric = value.replace(',', '.').toDoubleOrNull() ?: return null
        val bytes = (numeric * unit.multiplier).roundToLong()
        return bytes.takeIf { it in MIN_CUSTOM_BYTES..MAX_CUSTOM_BYTES }
    }

    private fun Exception.userMessage(fallback: String): String =
        (this as? UserVisibleException)?.message ?: fallback

    companion object {
        private const val MIN_CUSTOM_BYTES = 10_000L
        private const val MAX_CUSTOM_BYTES = 50_000_000L
        private const val MIN_CUSTOM_PIXELS = 32
        private const val MAX_CUSTOM_PIXELS = 12_000
    }
}
