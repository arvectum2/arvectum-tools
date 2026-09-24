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

val ArvectumMint = Color(0xFF43E5C5)
val ArvectumMintLight = Color(0xFF7AF1DD)
val ArvectumDeepNavy = Color(0xFF041A33)
val ArvectumGraphite = Color(0xFF243446)
val ArvectumSoftGray = Color(0xFFF3F5F7)
val ArvectumWhite = Color(0xFFFFFFFF)

private val LightColors = lightColorScheme(
    primary = ArvectumMint,
    onPrimary = ArvectumDeepNavy,
    primaryContainer = ArvectumMintLight,
    onPrimaryContainer = ArvectumDeepNavy,
    secondary = ArvectumGraphite,
    onSecondary = ArvectumWhite,
    background = ArvectumSoftGray,
    onBackground = ArvectumDeepNavy,
    surface = ArvectumWhite,
    onSurface = ArvectumDeepNavy,
    surfaceVariant = ArvectumSoftGray,
    onSurfaceVariant = ArvectumGraphite,
    outline = ArvectumGraphite.copy(alpha = 0.28f),
    outlineVariant = ArvectumGraphite.copy(alpha = 0.14f),
    error = Color(0xFFB3261E),
    onError = ArvectumWhite,
)

private val DarkColors = darkColorScheme(
    primary = ArvectumMint,
    onPrimary = ArvectumDeepNavy,
    primaryContainer = ArvectumGraphite,
    onPrimaryContainer = ArvectumMintLight,
    secondary = ArvectumMintLight,
    onSecondary = ArvectumDeepNavy,
    background = ArvectumDeepNavy,
    onBackground = ArvectumWhite,
    surface = ArvectumGraphite,
    onSurface = ArvectumWhite,
    surfaceVariant = ArvectumGraphite,
    onSurfaceVariant = ArvectumSoftGray.copy(alpha = 0.74f),
    outline = ArvectumMintLight.copy(alpha = 0.34f),
    outlineVariant = ArvectumWhite.copy(alpha = 0.10f),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
)

private val AppTypography = Typography().copy(
    headlineMedium = Typography().headlineMedium.copy(
        fontSize = 30.sp,
        fontWeight = FontWeight.Bold,
    ),
    headlineSmall = Typography().headlineSmall.copy(
        fontSize = 24.sp,
        fontWeight = FontWeight.Bold,
    ),
    titleLarge = Typography().titleLarge.copy(
        fontSize = 20.sp,
        fontWeight = FontWeight.SemiBold,
    ),
    titleMedium = Typography().titleMedium.copy(
        fontSize = 17.sp,
        fontWeight = FontWeight.SemiBold,
    ),
    bodyLarge = Typography().bodyLarge.copy(
        fontSize = 16.sp,
        lineHeight = 23.sp,
    ),
    bodyMedium = Typography().bodyMedium.copy(
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
    labelLarge = Typography().labelLarge.copy(
        fontSize = 15.sp,
        fontWeight = FontWeight.SemiBold,
    ),
    labelMedium = Typography().labelMedium.copy(
        fontSize = 12.sp,
        fontWeight = FontWeight.SemiBold,
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
