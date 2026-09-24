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
import kotlin.math.roundToLong

class MainViewModel(application: Application) : AndroidViewModel(application) {
    private val storage = ImageStorage(application)
    private val compressor = CompressionEngine(application)

    private val _state = MutableStateFlow(AppUiState())
    val state: StateFlow<AppUiState> = _state.asStateFlow()

    fun selectImage(uri: Uri) {
        _state.update { it.copy(isWorking = true, error = null, saved = false, result = null) }
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

    fun compress() {
        val snapshot = _state.value
        val source = snapshot.source ?: return
        val target = snapshot.targetBytes ?: return

        if (source.sizeBytes <= target) {
            _state.update {
                it.copy(
                    result = ResultImage(source, null, source.sizeBytes, target, alreadyFit = true),
                    saved = false,
                )
            }
            return
        }

        _state.update { it.copy(isWorking = true, error = null, saved = false) }
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val output = compressor.compress(source, target)
                _state.update {
                    it.copy(
                        isWorking = false,
                        result = ResultImage(
                            source = source,
                            outputFile = output.file,
                            outputSizeBytes = output.sizeBytes,
                            targetBytes = target,
                            alreadyFit = false,
                        ),
                    )
                }
            } catch (error: Exception) {
                _state.update {
                    it.copy(
                        isWorking = false,
                        error = error.userMessage("Не получилось уменьшить это изображение."),
                    )
                }
            }
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
        return "${base}-до-размера.jpg"
    }

    fun backToSelection() {
        _state.update { it.copy(result = null, saved = false, error = null) }
    }

    fun reset() {
        _state.value = AppUiState()
    }

    fun dismissError() {
        _state.update { it.copy(error = null) }
    }

    private fun currentResultForAction(): ResultImage? {
        val snapshot = _state.value
        snapshot.result?.let { return it }
        val source = snapshot.source ?: return null
        val target = snapshot.targetBytes ?: return null
        return if (source.sizeBytes <= target) {
            ResultImage(source, null, source.sizeBytes, target, alreadyFit = true)
        } else {
            null
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
    }
}
