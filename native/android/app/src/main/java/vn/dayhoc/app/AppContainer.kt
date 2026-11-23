package vn.dayhoc.app

import android.content.Context
import vn.dayhoc.app.core.auth.AuthApi
import vn.dayhoc.app.core.auth.AuthRepository
import vn.dayhoc.app.core.auth.KeystoreTokenStore
import vn.dayhoc.app.core.network.Network

/** DI thủ công: một instance cho cả app, tạo ở [DayHocApp]. */
class AppContainer(context: Context) {
    val tokenStore = KeystoreTokenStore(context)

    private val network = Network(
        apiUrl = BuildConfig.API_URL,
        tokenStore = tokenStore,
        clientInfo = "teachhub-app/${BuildConfig.VERSION_NAME} (android)",
        httpLogging = BuildConfig.HTTP_LOGGING,
    )

    /** Phát khi refresh token bị thu hồi; gốc điều hướng nghe để về màn đăng nhập. */
    val sessionExpired = network.authenticator.sessionExpired

    val authRepository = AuthRepository(network.retrofit.create(AuthApi::class.java), tokenStore)
}
