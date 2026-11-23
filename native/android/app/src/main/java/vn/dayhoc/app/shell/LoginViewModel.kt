package vn.dayhoc.app.shell

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import vn.dayhoc.app.core.auth.AuthRepository
import vn.dayhoc.app.core.network.ApiError

sealed interface LoginFailure {
    /** Sai mã: hiện tại ô nhập, không qua snackbar. */
    data class OtpInvalid(val attemptsLeft: Int?) : LoginFailure
    data object RateLimited : LoginFailure
    data object Unavailable : LoginFailure
    data object Network : LoginFailure
    data object Generic : LoginFailure
}

data class LoginUiState(
    val email: String = "",
    val showEmailError: Boolean = false,
    /** Email đã gửi mã; `null` = đang ở bước nhập email (T01), khác `null` = bước nhập mã (T01a). */
    val sentTo: String? = null,
    val code: String = "",
    val sending: Boolean = false,
    val verifying: Boolean = false,
    val resendIn: Int = 0,
    val lockedFor: Int = 0,
    val failure: LoginFailure? = null,
    val loggedIn: Boolean = false,
) {
    val emailValid: Boolean get() = EMAIL_PATTERN.matches(email.trim().lowercase())

    private companion object {
        val EMAIL_PATTERN = Regex("""^[^@\s]+@[^@\s]+\.[^@\s]+$""")
    }
}

/** [T01] Đăng nhập + [T01a] Nhập mã OTP. */
class LoginViewModel(private val auth: AuthRepository) : ViewModel() {
    private val _state = MutableStateFlow(LoginUiState())
    val state: StateFlow<LoginUiState> = _state.asStateFlow()

    private var resendJob: Job? = null
    private var lockJob: Job? = null

    fun onEmailChange(email: String) = _state.update { it.copy(email = email, showEmailError = false) }

    /** Gửi mã lần đầu và gửi lại; bị chặn khi còn đếm ngược. */
    fun sendCode() {
        val s = _state.value
        if (s.sending || s.resendIn > 0) return
        if (!s.emailValid) {
            _state.update { it.copy(showEmailError = true) }
            return
        }
        val email = s.email.trim().lowercase()
        _state.update { it.copy(sending = true, failure = null) }
        viewModelScope.launch {
            try {
                auth.sendOtp(email)
                _state.update { it.copy(sentTo = email, code = "") }
                startResendCountdown(RESEND_AFTER_SEC)
            } catch (e: ApiError) {
                _state.update { it.copy(failure = e.toFailure()) }
                // Server bảo chờ bao lâu thì khóa nút gửi lại đúng bấy lâu.
                if (e is ApiError.Http && (e.code == ApiError.RATE_LIMITED || e.httpStatus == 429)) {
                    e.retryAfterSec?.let(::startResendCountdown)
                }
            } finally {
                _state.update { it.copy(sending = false) }
            }
        }
    }

    fun onCodeChange(input: String) {
        val code = input.filter(Char::isDigit).take(CODE_LENGTH)
        _state.update { it.copy(code = code, failure = it.failure.takeUnless { f -> f is LoginFailure.OtpInvalid }) }
        if (code.length == CODE_LENGTH) verify()
    }

    fun verify() {
        val s = _state.value
        val email = s.sentTo ?: return
        if (s.code.length != CODE_LENGTH || s.lockedFor > 0 || s.verifying) return
        _state.update { it.copy(verifying = true, failure = null) }
        viewModelScope.launch {
            try {
                auth.login(email, s.code)
                _state.update { it.copy(loggedIn = true) }
            } catch (e: ApiError) {
                onLoginFailed(e)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Lưu token lỗi (Keystore/đĩa): báo lỗi chung, không crash.
                _state.update { it.copy(failure = LoginFailure.Generic) }
            } finally {
                _state.update { it.copy(verifying = false) }
            }
        }
    }

    fun changeEmail() {
        resendJob?.cancel()
        lockJob?.cancel()
        _state.update { it.copy(sentTo = null, code = "", failure = null, resendIn = 0, lockedFor = 0) }
    }

    /** Màn hình đã hiện snackbar lỗi. */
    fun failureShown() = _state.update { it.copy(failure = it.failure as? LoginFailure.OtpInvalid) }

    private fun onLoginFailed(e: ApiError) {
        when ((e as? ApiError.Http)?.code) {
            ApiError.OTP_INVALID -> _state.update {
                it.copy(failure = LoginFailure.OtpInvalid((e as ApiError.Http).detailInt("attemptsLeft")))
            }
            ApiError.OTP_LOCKED -> {
                lockJob?.cancel()
                lockJob = countdown((e as ApiError.Http).retryAfterSec ?: LOCK_DEFAULT_SEC) { st, sec ->
                    st.copy(lockedFor = sec, code = if (sec == 0) "" else st.code)
                }
            }
            else -> _state.update { it.copy(failure = e.toFailure()) }
        }
    }

    private fun startResendCountdown(seconds: Int) {
        resendJob?.cancel()
        resendJob = countdown(seconds) { st, sec -> st.copy(resendIn = sec) }
    }

    private fun countdown(seconds: Int, set: (LoginUiState, Int) -> LoginUiState): Job = viewModelScope.launch {
        for (sec in seconds downTo 1) {
            _state.update { set(it, sec) }
            delay(1_000)
        }
        _state.update { set(it, 0) }
    }

    companion object {
        /** Gửi lại OTP: 60 giây/lần (Technical Spec 5.2a). */
        const val RESEND_AFTER_SEC = 60
        const val LOCK_DEFAULT_SEC = 15 * 60
        const val CODE_LENGTH = 6
    }
}

private fun ApiError.toFailure(): LoginFailure = when (this) {
    ApiError.Network, ApiError.Timeout -> LoginFailure.Network
    ApiError.InvalidResponse -> LoginFailure.Generic
    is ApiError.Http -> when {
        code == ApiError.RATE_LIMITED || code == ApiError.OTP_LOCKED -> LoginFailure.RateLimited
        code == ApiError.SERVICE_UNAVAILABLE || httpStatus >= 500 -> LoginFailure.Unavailable
        else -> LoginFailure.Generic
    }
}
