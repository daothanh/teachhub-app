package vn.dayhoc.app.core.auth

import kotlinx.serialization.Serializable

@Serializable
data class Tokens(val accessToken: String, val refreshToken: String)

/**
 * Nơi giữ token. Interface chỉ để test thay bằng bản trong bộ nhớ, vì Android Keystore
 * không chạy trên JVM; bản thật là [KeystoreTokenStore].
 */
interface TokenStore {
    /** Bản trong bộ nhớ, interceptor đọc đồng bộ. `null` khi chưa [load] hoặc chưa đăng nhập. */
    val tokens: Tokens?

    suspend fun load(): Tokens?

    suspend fun save(tokens: Tokens)

    suspend fun clear()
}
