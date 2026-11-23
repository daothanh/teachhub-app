package vn.dayhoc.app.core.designsystem

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import vn.dayhoc.app.core.designsystem.TeachHubTokens.Dimens

/** Ô nhập: viền outline, khi lỗi viền và chữ phụ dùng màu error. */
@Composable
fun DhTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    placeholder: String? = null,
    supportingText: String? = null,
    isError: Boolean = false,
    enabled: Boolean = true,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
) {
    val colors = MaterialTheme.colorScheme
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        label = { Text(label) },
        placeholder = placeholder?.let { { Text(it) } },
        supportingText = supportingText?.let { { Text(it) } },
        isError = isError,
        enabled = enabled,
        singleLine = true,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        shape = RoundedCornerShape(Dimens.fieldRadius),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = colors.surface,
            unfocusedContainerColor = colors.surface,
            unfocusedBorderColor = colors.outline,
            focusedBorderColor = colors.secondary,
            focusedLabelColor = colors.secondary,
            cursorColor = colors.secondary,
            errorBorderColor = colors.error,
            errorLabelColor = colors.error,
            errorSupportingTextColor = colors.error,
            errorCursorColor = colors.error,
        ),
    )
}
