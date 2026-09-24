package ru.arvectum.tools.tosize.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

private val LightColors = lightColorScheme(
    primary = Color(0xFF315EFB),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFE9EEFF),
    onPrimaryContainer = Color(0xFF17347F),
    secondary = Color(0xFF616975),
    background = Color(0xFFF7F8FA),
    onBackground = Color(0xFF111318),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF111318),
    surfaceVariant = Color(0xFFF0F2F5),
    onSurfaceVariant = Color(0xFF616975),
    outline = Color(0xFFD9DEE6),
    error = Color(0xFFB3261E),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFF7894FF),
    onPrimary = Color(0xFF071A5C),
    primaryContainer = Color(0xFF202B50),
    onPrimaryContainer = Color(0xFFDDE4FF),
    secondary = Color(0xFFA8B0BA),
    background = Color(0xFF0D0F12),
    onBackground = Color(0xFFF4F6F8),
    surface = Color(0xFF15181D),
    onSurface = Color(0xFFF4F6F8),
    surfaceVariant = Color(0xFF1D2127),
    onSurfaceVariant = Color(0xFFA8B0BA),
    outline = Color(0xFF2B3139),
    error = Color(0xFFFFB4AB),
)

private val AppTypography = Typography().copy(
    headlineMedium = Typography().headlineMedium.copy(
        fontSize = 32.sp,
        fontWeight = FontWeight.SemiBold,
    ),
    headlineSmall = Typography().headlineSmall.copy(
        fontSize = 24.sp,
        fontWeight = FontWeight.SemiBold,
    ),
    titleMedium = Typography().titleMedium.copy(
        fontSize = 18.sp,
        fontWeight = FontWeight.Medium,
    ),
    bodyLarge = Typography().bodyLarge.copy(fontSize = 16.sp),
    bodyMedium = Typography().bodyMedium.copy(fontSize = 14.sp),
    labelLarge = Typography().labelLarge.copy(
        fontSize = 16.sp,
        fontWeight = FontWeight.Medium,
    ),
)

@Composable
fun ArvectumToolsTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors,
        typography = AppTypography,
        content = content,
    )
}
