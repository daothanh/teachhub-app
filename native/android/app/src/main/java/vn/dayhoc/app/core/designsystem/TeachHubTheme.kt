package vn.dayhoc.app.core.designsystem

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import vn.dayhoc.app.core.designsystem.TeachHubTokens.Dark
import vn.dayhoc.app.core.designsystem.TeachHubTokens.Dimens
import vn.dayhoc.app.core.designsystem.TeachHubTokens.Light

// Nền màn hình (background) = scaffoldBackground; Scaffold của M3 lấy màu này làm nền.
private val LightColors = lightColorScheme(
    primary = Light.primary,
    onPrimary = Light.onPrimary,
    primaryContainer = Light.primaryContainer,
    onPrimaryContainer = Light.onPrimaryContainer,
    secondary = Light.secondary,
    onSecondary = Light.onSecondary,
    secondaryContainer = Light.secondaryContainer,
    onSecondaryContainer = Light.onSecondaryContainer,
    error = Light.error,
    errorContainer = Light.errorContainer,
    onErrorContainer = Light.onErrorContainer,
    background = Light.scaffoldBackground,
    onBackground = Light.onSurface,
    surface = Light.surface,
    onSurface = Light.onSurface,
    onSurfaceVariant = Light.onSurfaceVariant,
    surfaceContainerLow = Light.surfaceContainerLow,
    surfaceContainerHighest = Light.surfaceContainerHighest,
    outline = Light.outline,
    outlineVariant = Light.outlineVariant,
    inverseSurface = Light.inverseSurface,
    inverseOnSurface = Light.onInverseSurface,
    surfaceTint = Light.surfaceTint,
)

private val DarkColors = darkColorScheme(
    primary = Dark.primary,
    onPrimary = Dark.onPrimary,
    primaryContainer = Dark.primaryContainer,
    onPrimaryContainer = Dark.onPrimaryContainer,
    secondary = Dark.secondary,
    onSecondary = Dark.onSecondary,
    secondaryContainer = Dark.secondaryContainer,
    onSecondaryContainer = Dark.onSecondaryContainer,
    error = Dark.error,
    errorContainer = Dark.errorContainer,
    onErrorContainer = Dark.onErrorContainer,
    background = Dark.scaffoldBackground,
    onBackground = Dark.onSurface,
    surface = Dark.surface,
    onSurface = Dark.onSurface,
    onSurfaceVariant = Dark.onSurfaceVariant,
    surfaceContainerLow = Dark.surfaceContainerLow,
    surfaceContainerHighest = Dark.surfaceContainerHighest,
    outline = Dark.outline,
    outlineVariant = Dark.outlineVariant,
    inverseSurface = Dark.inverseSurface,
    inverseOnSurface = Dark.onInverseSurface,
    surfaceTint = Dark.surfaceTint,
)

private val TeachHubShapes = Shapes(
    extraSmall = RoundedCornerShape(Dimens.checkboxRadius),
    small = RoundedCornerShape(Dimens.fieldRadius),
    medium = RoundedCornerShape(Dimens.cardRadius),
    large = RoundedCornerShape(Dimens.dialogRadius),
    extraLarge = RoundedCornerShape(Dimens.sheetRadius),
)

/** Theme DayHoc dựng hoàn toàn từ [TeachHubTokens]; font hệ thống (Be Vietnam Pro làm sau). */
@Composable
fun TeachHubTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        shapes = TeachHubShapes,
        content = content,
    )
}
