package vn.dayhoc.app.core.network

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import vn.dayhoc.app.core.auth.AuthApi
import vn.dayhoc.app.core.auth.RefreshRequest
import vn.dayhoc.app.core.auth.TokenStore
import vn.dayhoc.app.core.auth.Tokens
import vn.dayhoc.app.core.network.HeaderInterceptor.Companion.AUTHORIZATION

/**
 * Gặp 401 thì làm mới token MỘT LUỒNG: các request cùng nhận 401 xếp hàng sau [sessionMutex];
 * request đầu gọi `/auth/refresh`, các request sau thấy token đã đổi thì dùng luôn.
 * Refresh bị từ chối (401/403) → xóa token và bật [sessionExpired] để app về màn đăng nhập.
 *
 * [sessionMutex] dùng chung với đăng nhập/đăng xuất ([vn.dayhoc.app.core.auth.AuthRepository])
 * để kết quả refresh không ghi đè phiên vừa đổi.
 *
 * [refreshApi] phải dựng trên client KHÔNG có authenticator này, và gọi đồng bộ (`execute`)
 * để không chiếm chỗ trong hàng đợi async đang bị các request chờ giữ.
 */
class TokenAuthenticator(
    private val tokenStore: TokenStore,
    private val refreshApi: AuthApi,
    private val sessionMutex: Mutex = Mutex(),
) : Authenticator {
    /** `true` khi phiên hết hạn; UI xử lý xong thì đặt lại `false` (StateFlow giữ sự kiện, không mất khi chưa ai nghe). */
    val sessionExpired = MutableStateFlow(false)

    override fun authenticate(route: Route?, response: Response): Request? {
        // Request không mang Bearer (đăng nhập, refresh) hoặc đã thử lại một lần: không làm mới nữa.
        val sent = response.request.header(AUTHORIZATION) ?: return null
        if (response.priorResponse != null) return null
        val fresh = runBlocking { sessionMutex.withLock { freshTokens(sent.removePrefix("Bearer ")) } } ?: return null
        return response.request.newBuilder().header(AUTHORIZATION, "Bearer ${fresh.accessToken}").build()
    }

    private suspend fun freshTokens(failedAccessToken: String): Tokens? {
        val current = tokenStore.tokens ?: return null
        if (current.accessToken != failedAccessToken) return current
        val result = try {
            refreshApi.refresh(RefreshRequest(current.refreshToken)).execute()
        } catch (e: Exception) {
            // Mất mạng hoặc body sai hợp đồng: giữ phiên, request này thất bại, lần sau thử lại.
            // Bắt rộng vì ngoại lệ không phải IOException thoát khỏi authenticator làm sập luồng OkHttp.
            return null
        }
        // Trong lúc chờ refresh, phiên đã đổi (đăng xuất/đăng nhập lại): kết quả này không còn thuộc về phiên nào.
        if (tokenStore.tokens?.refreshToken != current.refreshToken) return null
        val body = result.body()
        if (!result.isSuccessful || body == null) {
            // Chỉ 401/403 nghĩa là refresh token chết; 4xx khác (429, 408…) và 5xx giữ phiên.
            if (result.code() == 401 || result.code() == 403) {
                tokenStore.clear()
                sessionExpired.value = true
            }
            return null
        }
        val fresh = Tokens(body.accessToken, body.refreshToken)
        try {
            tokenStore.save(fresh)
        } catch (e: Exception) {
            // Lỗi lưu không được thoát khỏi authenticate; request này vẫn dùng token mới.
        }
        return fresh
    }
}
