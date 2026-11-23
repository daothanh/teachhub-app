package vn.dayhoc.app.core.network

import java.io.IOException
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
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
 * Gặp 401 thì làm mới token MỘT LUỒNG: các request cùng nhận 401 xếp hàng sau [mutex];
 * request đầu gọi `/auth/refresh`, các request sau thấy token đã đổi thì dùng luôn.
 * Refresh bị từ chối (4xx) → xóa token và phát [sessionExpired] để app về màn đăng nhập.
 *
 * [refreshApi] phải dựng trên client KHÔNG có authenticator này, và gọi đồng bộ (`execute`)
 * để không chiếm chỗ trong hàng đợi async đang bị các request chờ giữ.
 */
class TokenAuthenticator(
    private val tokenStore: TokenStore,
    private val refreshApi: AuthApi,
) : Authenticator {
    private val mutex = Mutex()
    private val _sessionExpired = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val sessionExpired: SharedFlow<Unit> = _sessionExpired

    override fun authenticate(route: Route?, response: Response): Request? {
        // Request không mang Bearer (đăng nhập, refresh) hoặc đã thử lại một lần: không làm mới nữa.
        val sent = response.request.header(AUTHORIZATION) ?: return null
        if (response.priorResponse != null) return null
        val fresh = runBlocking { mutex.withLock { freshTokens(sent.removePrefix("Bearer ")) } } ?: return null
        return response.request.newBuilder().header(AUTHORIZATION, "Bearer ${fresh.accessToken}").build()
    }

    private suspend fun freshTokens(failedAccessToken: String): Tokens? {
        val current = tokenStore.tokens ?: return null
        if (current.accessToken != failedAccessToken) return current
        val result = try {
            refreshApi.refresh(RefreshRequest(current.refreshToken)).execute()
        } catch (e: IOException) {
            // Mất mạng khi làm mới: giữ phiên, request này thất bại, lần sau thử lại.
            return null
        }
        val body = result.body()
        if (!result.isSuccessful || body == null) {
            // 429 chỉ là giới hạn tần suất: giữ phiên. 4xx khác nghĩa là refresh token không dùng được nữa.
            if (result.code() in 400..499 && result.code() != 429) {
                tokenStore.clear()
                _sessionExpired.tryEmit(Unit)
            }
            return null
        }
        return Tokens(body.accessToken, body.refreshToken).also { tokenStore.save(it) }
    }
}
