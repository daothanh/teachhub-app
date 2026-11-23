package vn.dayhoc.app.shell

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import retrofit2.Call
import retrofit2.HttpException
import retrofit2.Response
import vn.dayhoc.app.core.auth.AuthApi
import vn.dayhoc.app.core.auth.AuthRepository
import vn.dayhoc.app.core.auth.InMemoryTokenStore
import vn.dayhoc.app.core.auth.LoginRequest
import vn.dayhoc.app.core.auth.LoginResponse
import vn.dayhoc.app.core.auth.MembershipsResponse
import vn.dayhoc.app.core.auth.RefreshRequest
import vn.dayhoc.app.core.auth.SendOtpRequest
import vn.dayhoc.app.core.auth.TokenResponse
import vn.dayhoc.app.core.auth.TokenStore
import vn.dayhoc.app.core.auth.Tokens
import vn.dayhoc.app.core.auth.UserDto

@OptIn(ExperimentalCoroutinesApi::class)
class LoginViewModelTest {
    private val api = FakeAuthApi()
    private val store = InMemoryTokenStore()
    private lateinit var vm: LoginViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(StandardTestDispatcher())
        vm = LoginViewModel(AuthRepository(api, store))
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `gui ma thanh cong chuyen sang buoc nhap ma`() = runTest {
        vm.onEmailChange(" Co.Lan@Example.com ")
        vm.sendCode()
        runCurrent()

        val s = vm.state.value
        assertEquals("co.lan@example.com", s.sentTo)
        assertEquals(listOf("co.lan@example.com"), api.sentTo)
        assertEquals(LoginViewModel.RESEND_AFTER_SEC, s.resendIn)
        assertFalse(s.sending)
    }

    @Test
    fun `email sai dinh dang thi bao loi va khong goi api`() = runTest {
        vm.onEmailChange("co.lan@")
        vm.sendCode()
        runCurrent()

        assertTrue(vm.state.value.showEmailError)
        assertNull(vm.state.value.sentTo)
        assertTrue(api.sentTo.isEmpty())
    }

    @Test
    fun `sai ma hien loi OTP_INVALID kem so lan con lai`() = runTest {
        sendCodeTo("co.lan@example.com")
        api.loginError = httpError(401, """{"code":"OTP_INVALID","message":"x","details":{"attemptsLeft":3},"requestId":"r"}""")

        vm.onCodeChange("123456")
        runCurrent()

        val s = vm.state.value
        assertEquals(LoginFailure.OtpInvalid(attemptsLeft = 3), s.failure)
        assertFalse(s.loggedIn)
        assertFalse(s.verifying)
        assertNull(store.tokens)
    }

    @Test
    fun `nhap sai qua 5 lan thi tam khoa theo retryAfterSec`() = runTest {
        sendCodeTo("co.lan@example.com")
        api.loginError = httpError(429, """{"code":"OTP_LOCKED","message":"x","details":{"retryAfterSec":900},"requestId":"r"}""")

        vm.onCodeChange("123456")
        runCurrent()

        assertEquals(900, vm.state.value.lockedFor)
        assertNull(vm.state.value.failure)
    }

    @Test
    fun `dung ma thi dang nhap va luu token`() = runTest {
        sendCodeTo("co.lan@example.com")

        vm.onCodeChange("482913")
        runCurrent()

        assertTrue(vm.state.value.loggedIn)
        assertEquals(LoginRequest("email_otp", "co.lan@example.com", "482913"), api.lastLogin)
        assertEquals(Tokens("access", "refresh"), store.tokens)
    }

    @Test
    fun `nut gui lai bi khoa trong 60 giay`() = runTest {
        sendCodeTo("co.lan@example.com")

        advanceTimeBy(59_000)
        assertTrue(vm.state.value.resendIn > 0)
        vm.sendCode()
        runCurrent()
        assertEquals(1, api.sentTo.size)

        advanceTimeBy(1_001)
        assertEquals(0, vm.state.value.resendIn)
        vm.sendCode()
        runCurrent()
        assertEquals(2, api.sentTo.size)
    }

    @Test
    fun `gui ma bi RATE_LIMITED thi dem nguoc gui lai theo retryAfterSec`() = runTest {
        api.sendError = httpError(429, """{"code":"RATE_LIMITED","message":"x","details":{"retryAfterSec":42},"requestId":"r"}""")

        sendCodeTo("co.lan@example.com")

        assertEquals(LoginFailure.RateLimited, vm.state.value.failure)
        assertEquals(42, vm.state.value.resendIn)
    }

    @Test
    fun `luu token loi thi bao loi chung khong crash`() = runTest {
        val brokenStore = object : TokenStore {
            override val tokens: Tokens? = null
            override suspend fun load(): Tokens? = null
            override suspend fun save(tokens: Tokens) {
                throw java.security.KeyStoreException("keystore hỏng")
            }
            override suspend fun clear() = Unit
        }
        vm = LoginViewModel(AuthRepository(api, brokenStore))
        sendCodeTo("co.lan@example.com")

        vm.onCodeChange("482913")
        runCurrent()

        assertEquals(LoginFailure.Generic, vm.state.value.failure)
        assertFalse(vm.state.value.loggedIn)
        assertFalse(vm.state.value.verifying)
    }

    private fun kotlinx.coroutines.test.TestScope.sendCodeTo(email: String) {
        vm.onEmailChange(email)
        vm.sendCode()
        runCurrent()
    }

    private fun httpError(status: Int, body: String) =
        HttpException(Response.error<Any>(status, body.toResponseBody("application/json".toMediaType())))
}

private class FakeAuthApi : AuthApi {
    val sentTo = mutableListOf<String>()
    var lastLogin: LoginRequest? = null
    var loginError: HttpException? = null
    var sendError: HttpException? = null

    override suspend fun sendOtp(body: SendOtpRequest) {
        sentTo += body.email
        sendError?.let { throw it }
    }

    override suspend fun login(body: LoginRequest): LoginResponse {
        lastLogin = body
        loginError?.let { throw it }
        return LoginResponse("access", "refresh", 900, UserDto("u1", body.email, "Cô Lan", emptyList()))
    }

    override fun refresh(body: RefreshRequest): Call<TokenResponse> = error("không dùng trong test này")

    override suspend fun me(): UserDto = error("không dùng trong test này")

    override suspend fun logout() = Unit

    override suspend fun memberships(): MembershipsResponse = error("không dùng trong test này")
}
