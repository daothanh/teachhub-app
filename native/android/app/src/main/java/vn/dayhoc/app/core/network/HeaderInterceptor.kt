package vn.dayhoc.app.core.network

import java.util.UUID
import okhttp3.Interceptor
import okhttp3.Response
import vn.dayhoc.app.core.auth.TokenStore

/** Gắn `x-request-id`, `x-client-info` cho mọi request và Bearer cho endpoint cần đăng nhập. */
class HeaderInterceptor(
    private val tokenStore: TokenStore,
    private val clientInfo: String,
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val builder = request.newBuilder()
            .header("x-request-id", UUID.randomUUID().toString())
            .header("x-client-info", clientInfo)
        val path = request.url.encodedPath
        val token = tokenStore.tokens?.accessToken
        if (token != null && PUBLIC_PATHS.none(path::endsWith)) {
            builder.header(AUTHORIZATION, "Bearer $token")
        }
        return chain.proceed(builder.build())
    }

    companion object {
        const val AUTHORIZATION = "Authorization"
        private val PUBLIC_PATHS = listOf("/auth/otp/send", "/auth/login", "/auth/refresh")
    }
}
