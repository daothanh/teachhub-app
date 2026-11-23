package vn.dayhoc.app

import android.content.Context
import vn.dayhoc.app.core.auth.AuthApi
import vn.dayhoc.app.core.auth.AuthRepository
import vn.dayhoc.app.core.auth.KeystoreTokenStore
import kotlinx.coroutines.sync.Mutex
import vn.dayhoc.app.core.network.Network

/** DI thủ công: một instance cho cả app, tạo ở [DayHocApp]. */
class AppContainer(context: Context) {
    val tokenStore = KeystoreTokenStore(context)

    /** Khóa chung cho refresh, đăng nhập, đăng xuất: không để kết quả refresh cũ ghi đè phiên mới. */
    private val sessionMutex = Mutex()

    private val network = Network(
        apiUrl = BuildConfig.API_URL,
        tokenStore = tokenStore,
        clientInfo = "teachhub-app/${BuildConfig.VERSION_NAME} (android)",
        httpLogging = BuildConfig.DEBUG && BuildConfig.HTTP_LOGGING,
        sessionMutex = sessionMutex,
    )

    /** `true` khi refresh token bị thu hồi; gốc điều hướng về màn đăng nhập rồi đặt lại `false`. */
    val sessionExpired = network.authenticator.sessionExpired

    val authRepository = AuthRepository(network.retrofit.create(AuthApi::class.java), tokenStore, sessionMutex)
}
