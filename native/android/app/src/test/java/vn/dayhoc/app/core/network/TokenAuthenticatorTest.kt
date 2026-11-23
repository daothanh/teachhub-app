package vn.dayhoc.app.core.network

import app.cash.turbine.test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import mockwebserver3.Dispatcher
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.Request
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
    fun `refresh tra 401 thi xoa token va phat su kien het phien`() = runTest {
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                if (request.url.encodedPath == "/v1/auth/refresh") refreshCalls.incrementAndGet()
                return json(401, """{"code":"UNAUTHENTICATED","message":"thu hoi","requestId":"r2"}""")
            }
        }

        network.authenticator.sessionExpired.test {
            val code = withContext(Dispatchers.IO) {
                network.client.newCall(Request.Builder().url(server.url("/v1/auth/me")).build())
                    .execute()
                    .use { it.code }
            }
            assertEquals(401, code)
            awaitItem()
        }
        assertEquals(1, refreshCalls.get())
        assertNull(store.tokens)
    }

    private fun json(code: Int, body: String) = MockResponse.Builder()
        .code(code)
        .addHeader("Content-Type", "application/json")
        .body(body)
        .build()
}
