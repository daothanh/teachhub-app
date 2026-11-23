package vn.dayhoc.app.core.auth

import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

interface AuthApi {
    @POST("auth/otp/send")
    suspend fun sendOtp(@Body body: SendOtpRequest)

    @POST("auth/login")
    suspend fun login(@Body body: LoginRequest): LoginResponse

    /** Gọi đồng bộ từ [vn.dayhoc.app.core.network.TokenAuthenticator], không qua hàng đợi của OkHttp. */
    @POST("auth/refresh")
    fun refresh(@Body body: RefreshRequest): Call<TokenResponse>

    @GET("auth/me")
    suspend fun me(): UserDto

    @POST("auth/logout")
    suspend fun logout()

    @GET("me/memberships")
    suspend fun memberships(): MembershipsResponse
}
