package vn.dayhoc.app.shell

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import vn.dayhoc.app.R
import vn.dayhoc.app.core.designsystem.DhPrimaryButton
import vn.dayhoc.app.core.designsystem.DhTextField
import vn.dayhoc.app.core.designsystem.TeachHubTokens.Dimens

/** [T01] Đăng nhập · [T01a] Nhập mã OTP. Chưa có Google/Apple (làm ở task SSO). */
@Composable
fun LoginScreen(viewModel: LoginViewModel, onLoggedIn: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }

    LaunchedEffect(state.loggedIn) { if (state.loggedIn) onLoggedIn() }

    val toastFailure = state.failure?.takeUnless { it is LoginFailure.OtpInvalid }
    val toastMessage = toastFailure?.let { failureText(it) }
    LaunchedEffect(toastFailure) {
        if (toastMessage != null) {
            snackbar.showSnackbar(toastMessage)
            viewModel.failureShown()
        }
    }

    BackHandler(enabled = state.sentTo != null && !state.verifying) { viewModel.changeEmail() }

    Scaffold(snackbarHost = { SnackbarHost(snackbar) }) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(Dimens.spacingPage),
            verticalArrangement = Arrangement.spacedBy(Dimens.spacingContent),
        ) {
            if (state.sentTo == null) EmailStep(state, viewModel) else OtpStep(state, viewModel)
        }
    }
}

@Composable
private fun EmailStep(state: LoginUiState, viewModel: LoginViewModel) {
    val type = MaterialTheme.typography
    Text(stringResource(R.string.app_name), style = type.headlineLarge)
    Text(stringResource(R.string.login_slogan), style = type.headlineMedium)
    Text(
        stringResource(R.string.login_tagline),
        style = type.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    DhTextField(
        value = state.email,
        onValueChange = viewModel::onEmailChange,
        label = stringResource(R.string.login_email),
        placeholder = stringResource(R.string.login_email_hint),
        supportingText = stringResource(
            if (state.showEmailError) R.string.login_email_invalid else R.string.login_email_helper,
        ),
        isError = state.showEmailError,
        enabled = !state.sending,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Send),
        keyboardActions = KeyboardActions(onSend = { viewModel.sendCode() }),
        modifier = Modifier.fillMaxWidth(),
    )
    DhPrimaryButton(
        text = stringResource(R.string.login_send_otp),
        loadingText = stringResource(R.string.login_sending),
        loading = state.sending,
        enabled = state.emailValid,
        onClick = viewModel::sendCode,
    )
}

@Composable
private fun OtpStep(state: LoginUiState, viewModel: LoginViewModel) {
    val type = MaterialTheme.typography
    val colors = MaterialTheme.colorScheme
    val locked = state.lockedFor > 0
    val invalid = state.failure as? LoginFailure.OtpInvalid

    Text(stringResource(R.string.otp_title), style = type.titleMedium)
    if (locked) LockedBanner()
    Text(stringResource(R.string.otp_heading), style = type.headlineMedium)
    Text(
        stringResource(R.string.otp_sent_to, state.sentTo.orEmpty()),
        style = type.bodyMedium,
        color = colors.onSurfaceVariant,
    )
    TextButton(onClick = viewModel::changeEmail, enabled = !state.verifying) {
        Text(stringResource(R.string.login_change_email))
    }
    DhTextField(
        value = state.code,
        onValueChange = viewModel::onCodeChange,
        label = stringResource(R.string.otp_code_label),
        supportingText = invalid?.let { failureText(it) },
        isError = invalid != null,
        enabled = !locked && !state.verifying,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword, imeAction = ImeAction.Done),
        keyboardActions = KeyboardActions(onDone = { viewModel.verify() }),
        modifier = Modifier.fillMaxWidth(),
    )
    Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        when {
            locked -> Text(stringResource(R.string.otp_retry_in, mmss(state.lockedFor)), color = colors.onSurfaceVariant)
            state.resendIn > 0 ->
                Text(stringResource(R.string.otp_resend_in, mmss(state.resendIn)), color = colors.onSurfaceVariant)
            else -> TextButton(onClick = viewModel::sendCode, enabled = !state.sending) {
                Text(stringResource(R.string.login_resend))
            }
        }
    }
    if (locked) {
        DhPrimaryButton(text = stringResource(R.string.otp_locked), onClick = {}, enabled = false)
    } else {
        DhPrimaryButton(
            text = stringResource(R.string.otp_confirm),
            loadingText = stringResource(R.string.otp_verifying),
            loading = state.verifying,
            enabled = state.code.length == LoginViewModel.CODE_LENGTH,
            onClick = viewModel::verify,
        )
    }
}

/** Banner lỗi khi bị tạm khóa (Figma B24). */
@Composable
private fun LockedBanner() {
    val colors = MaterialTheme.colorScheme
    Surface(
        shape = RoundedCornerShape(Dimens.cardRadius),
        color = colors.surface,
        border = BorderStroke(Dimens.focusRingWidth, colors.error),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(Dimens.spacingContent), verticalArrangement = Arrangement.spacedBy(Dimens.spacingInline)) {
            Text(
                stringResource(R.string.otp_locked_title),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
            )
            Text(
                stringResource(R.string.otp_locked_body),
                style = MaterialTheme.typography.bodySmall,
                color = colors.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun failureText(failure: LoginFailure): String = when (failure) {
    is LoginFailure.OtpInvalid -> failure.attemptsLeft
        ?.let { stringResource(R.string.otp_invalid_attempts, it) }
        ?: stringResource(R.string.otp_invalid)
    LoginFailure.RateLimited -> stringResource(R.string.login_rate_limited)
    LoginFailure.Unavailable -> stringResource(R.string.login_unavailable)
    LoginFailure.Network -> stringResource(R.string.error_network)
    LoginFailure.Generic -> stringResource(R.string.login_failed)
}

private fun mmss(seconds: Int) = "${seconds / 60}:${(seconds % 60).toString().padStart(2, '0')}"
