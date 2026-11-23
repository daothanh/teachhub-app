package vn.dayhoc.app.core.network

import java.util.concurrent.TimeUnit
import kotlinx.coroutines.sync.Mutex
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import vn.dayhoc.app.core.auth.AuthApi
import vn.dayhoc.app.core.auth.TokenStore

/**
 * Một client API duy nhất của app (Technical Spec Mục 3.5). [apiUrl] dạng `https://api.dayhoc.app/v1`.
 * [httpLogging] chỉ log header (Authorization bị che): body có OTP và token nên không bao giờ log.
 */
class Network(
    apiUrl: String,
    tokenStore: TokenStore,
    clientInfo: String,
    httpLogging: Boolean,
    sessionMutex: Mutex = Mutex(),
) {
    private val baseClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(HeaderInterceptor(tokenStore, clientInfo))
        .apply {
            if (httpLogging) {
                addInterceptor(
                    HttpLoggingInterceptor().apply {
                        level = HttpLoggingInterceptor.Level.HEADERS
                        redactHeader(HeaderInterceptor.AUTHORIZATION)
                    },
                )
            }
        }
        .build()

    private val json = Json { ignoreUnknownKeys = true }
    private val baseUrl = apiUrl.trimEnd('/') + "/"

    private fun retrofit(client: OkHttpClient): Retrofit = Retrofit.Builder()
        .baseUrl(baseUrl)
        .client(client)
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .build()

    val authenticator = TokenAuthenticator(tokenStore, retrofit(baseClient).create(AuthApi::class.java), sessionMutex)

    val client: OkHttpClient = baseClient.newBuilder().authenticator(authenticator).build()

    val retrofit: Retrofit = retrofit(client)
}
