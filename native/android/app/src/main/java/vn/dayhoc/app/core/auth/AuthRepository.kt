package vn.dayhoc.app.core.auth

import vn.dayhoc.app.core.network.ApiError
import vn.dayhoc.app.core.network.apiCall

/** Đăng nhập email OTP, phiên và vai trò. Mọi lỗi ném ra là [ApiError]. */
class AuthRepository(
    private val api: AuthApi,
    private val tokenStore: TokenStore,
) {
    suspend fun sendOtp(email: String) = apiCall { api.sendOtp(SendOtpRequest(email)) }

    suspend fun login(email: String, code: String): UserDto {
        val response = apiCall { api.login(LoginRequest(method = "email_otp", email = email, code = code)) }
        tokenStore.save(Tokens(response.accessToken, response.refreshToken))
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
            tokenStore.clear()
        }
    }
}
