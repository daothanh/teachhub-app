package vn.dayhoc.app.core.auth

import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import vn.dayhoc.app.core.network.ApiError
import vn.dayhoc.app.core.network.apiCall

/**
 * Đăng nhập email OTP, phiên và vai trò. Lỗi API ném ra là [ApiError].
 * [sessionMutex] dùng chung với [vn.dayhoc.app.core.network.TokenAuthenticator]: chỉ khóa quanh lúc ghi token,
 * không khóa quanh lời gọi mạng (request có thể 401 và cần chính khóa này để refresh).
 */
class AuthRepository(
    private val api: AuthApi,
    private val tokenStore: TokenStore,
    private val sessionMutex: Mutex = Mutex(),
) {
    suspend fun sendOtp(email: String) = apiCall { api.sendOtp(SendOtpRequest(email)) }

    suspend fun login(email: String, code: String): UserDto {
        val response = apiCall { api.login(LoginRequest(method = "email_otp", email = email, code = code)) }
        sessionMutex.withLock { tokenStore.save(Tokens(response.accessToken, response.refreshToken)) }
        return response.user
    }

    suspend fun me(): UserDto = apiCall { api.me() }

    suspend fun memberships(): MembershipsResponse = apiCall { api.memberships() }

    /** Thu hồi phiên trên server nếu được; token trên máy luôn bị xóa. */
    suspend fun logout() {
        try {
            apiCall { api.logout() }
        } catch (e: ApiError) {
            // Mất mạng hoặc phiên đã hết hạn: vẫn đăng xuất trên máy.
        } finally {
            // NonCancellable: rời màn hình giữa chừng vẫn phải xóa token.
            withContext(NonCancellable) { sessionMutex.withLock { tokenStore.clear() } }
        }
    }
}
