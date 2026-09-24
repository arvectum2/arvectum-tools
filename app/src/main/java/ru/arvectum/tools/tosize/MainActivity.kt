package ru.arvectum.tools.tosize

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import ru.arvectum.tools.tosize.ui.ArvectumToolsTheme
import ru.arvectum.tools.tosize.ui.MainScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            ArvectumToolsTheme {
                val viewModel: MainViewModel = viewModel()
                val state by viewModel.state.collectAsStateWithLifecycle()

                val imagePicker = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.PickVisualMedia(),
                ) { uri ->
                    if (uri != null) viewModel.selectImage(uri)
                }

                val saveDocument = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.CreateDocument("*/*"),
                ) { uri ->
                    if (uri != null) viewModel.saveTo(uri)
                }

                MainScreen(
                    state = state,
                    onPickImage = {
                        imagePicker.launch(
                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
                        )
                    },
                    onPreset = viewModel::setPreset,
                    onCustomMode = viewModel::startCustomTarget,
                    onCustomValue = viewModel::setCustomValue,
                    onCustomUnit = viewModel::setCustomUnit,
                    onCompress = viewModel::compress,
                    onSave = {
                        saveDocument.launch(viewModel.suggestedFileName())
                    },
                    onShare = {
                        viewModel.shareIntent()?.let { share ->
                            startActivity(Intent.createChooser(share, "Поделиться"))
                        }
                    },
                    onBackToSelection = viewModel::backToSelection,
                    onReset = viewModel::reset,
                    onDismissError = viewModel::dismissError,
                )
            }
        }
    }
}
