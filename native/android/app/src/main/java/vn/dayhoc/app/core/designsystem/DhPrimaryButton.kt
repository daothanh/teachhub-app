package vn.dayhoc.app.core.designsystem

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import vn.dayhoc.app.core.designsystem.TeachHubTokens.Dimens

/**
 * Nút chính: nền primary (lime), chữ onPrimary. Khi [loading] giữ nền lime, hiện spinner
 * và [loadingText] (Figma B03, B32); không bấm được khi loading hoặc [enabled] = false.
 */
@Composable
fun DhPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
    loadingText: String = text,
) {
    val colors = MaterialTheme.colorScheme
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = modifier.fillMaxWidth().defaultMinSize(minHeight = 48.dp),
        shape = RoundedCornerShape(Dimens.buttonRadius),
        elevation = ButtonDefaults.buttonElevation(defaultElevation = Dimens.buttonElevation),
        colors = ButtonDefaults.buttonColors(
            containerColor = colors.primary,
            contentColor = colors.onPrimary,
            disabledContainerColor = if (loading) colors.primary else colors.surfaceContainerHighest,
            disabledContentColor = if (loading) colors.onPrimary else colors.onSurfaceVariant,
        ),
    ) {
        if (loading) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = colors.onPrimary,
                )
                Spacer(Modifier.width(Dimens.spacingControl))
                Text(loadingText, style = MaterialTheme.typography.labelLarge)
            }
        } else {
            Text(text, style = MaterialTheme.typography.labelLarge)
        }
    }
}
