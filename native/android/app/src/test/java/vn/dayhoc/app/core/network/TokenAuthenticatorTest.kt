package vn.dayhoc.app.core.network

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.runBlocking
import mockwebserver3.Dispatcher
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import mockwebserver3.SocketEffect
import okhttp3.Request
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import vn.dayhoc.app.core.auth.InMemoryTokenStore
import vn.dayhoc.app.core.auth.Tokens

class TokenAuthenticatorTest {
    private val server = MockWebServer()
    private val store = InMemoryTokenStore(Tokens(accessToken = "old", refreshToken = "rt-old"))
    private val refreshCalls = AtomicInteger()
    private lateinit var network: Network

    @Before
    fun setUp() {
        server.start()
        network = Network(server.url("/v1").toString(), store, "teachhub-app/test (android)", httpLogging = false)
    }

    @After
    fun tearDown() {
        server.close()
    }

    @Test
    fun `ba request cung nhan 401 chi goi refresh mot lan va deu thanh cong voi token moi`() {
        // Giữ cả 3 request token cũ tới khi đủ 3 cái cùng tới, để chắc chắn chúng 401 song song.
        val oldTokenArrived = CountDownLatch(3)
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse = when {
                request.url.encodedPath == "/v1/auth/refresh" -> {
                    refreshCalls.incrementAndGet()
                    json(200, """{"access_token":"new","refresh_token":"rt-new","expires_in":900}""")
                }
                request.headers["Authorization"] == "Bearer new" -> json(200, """{"items":[],"lastMembershipId":null}""")
                else -> {
                    oldTokenArrived.countDown()
                    oldTokenArrived.await(5, TimeUnit.SECONDS)
                    json(401, """{"code":"TOKEN_EXPIRED","message":"het han","requestId":"r1"}""")
                }
            }
        }

        val pool = Executors.newFixedThreadPool(3)
        val codes = List(3) {
            pool.submit<Int> {
                network.client.newCall(Request.Builder().url(server.url("/v1/me/memberships")).build())
                    .execute()
                    .use { it.code }
            }
        }.map { it.get(15, TimeUnit.SECONDS) }
        pool.shutdown()

        assertEquals(listOf(200, 200, 200), codes)
        assertEquals(1, refreshCalls.get())
        assertEquals(Tokens("new", "rt-new"), store.tokens)
    }

    @Test
    fun `refresh tra 401 thi xoa token va bao het phien`() {
        refreshRespondsWith { json(401, """{"code":"UNAUTHENTICATED","message":"thu hoi","requestId":"r2"}""") }

        assertEquals(401, getMe())
        assertEquals(1, refreshCalls.get())
        assertNull(store.tokens)
        assertTrue(network.authenticator.sessionExpired.value)
    }

    @Test
    fun `refresh tra 500 thi giu phien`() {
        refreshRespondsWith { json(500, """{"code":"INTERNAL","message":"x","requestId":"r3"}""") }
        assertSessionKept()
    }

    @Test
    fun `refresh tra 429 thi giu phien`() {
        refreshRespondsWith { json(429, """{"code":"RATE_LIMITED","message":"x","details":{"retryAfterSec":30},"requestId":"r4"}""") }
        assertSessionKept()
    }

    @Test
    fun `refresh mat mang thi giu phien`() {
        refreshRespondsWith { MockResponse.Builder().onResponseStart(SocketEffect.CloseSocket()).build() }
        assertSessionKept()
    }

    @Test
    fun `dang xuat trong luc refresh dang chay thi token khong song lai`() {
        refreshRespondsWith {
            // Đăng xuất xen vào giữa lúc server đang xử lý refresh.
            runBlocking { store.clear() }
            json(200, """{"access_token":"new","refresh_token":"rt-new","expires_in":900}""")
        }

        assertEquals(401, getMe())
        assertNull(store.tokens)
        assertFalse(network.authenticator.sessionExpired.value)
    }

    /** `/auth/refresh` trả [refresh]; mọi request khác trả 401. */
    private fun refreshRespondsWith(refresh: () -> MockResponse) {
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                if (request.url.encodedPath != "/v1/auth/refresh") {
                    return json(401, """{"code":"TOKEN_EXPIRED","message":"het han","requestId":"r1"}""")
                }
                refreshCalls.incrementAndGet()
                return refresh()
            }
        }
    }

    private fun getMe(): Int =
        network.client.newCall(Request.Builder().url(server.url("/v1/auth/me")).build()).execute().use { it.code }

    private fun assertSessionKept() {
        assertEquals(401, getMe())
        assertTrue(refreshCalls.get() >= 1)
        assertEquals(Tokens("old", "rt-old"), store.tokens)
        assertFalse(network.authenticator.sessionExpired.value)
    }

    private fun json(code: Int, body: String) = MockResponse.Builder()
        .code(code)
        .addHeader("Content-Type", "application/json")
        .body(body)
        .build()
}
