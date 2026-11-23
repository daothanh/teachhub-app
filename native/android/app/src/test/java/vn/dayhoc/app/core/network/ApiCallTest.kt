package vn.dayhoc.app.core.network

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.SerializationException
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.fail
import org.junit.Test
import retrofit2.HttpException
import retrofit2.Response

class ApiCallTest {
    @Test
    fun bodySaiHopDongThanhInvalidResponseKhongCrash() = runTest {
        try {
            apiCall<Unit> { throw SerializationException("thiếu trường access_token") }
            fail("phải ném ApiError")
        } catch (e: ApiError) {
            assertEquals(ApiError.InvalidResponse, e)
        }
    }

    @Test
    fun httpExceptionDocCodeVaRetryAfterSecTuBody() = runTest {
        val e = httpError(429, """{"code":"RATE_LIMITED","message":"x","details":{"retryAfterSec":42},"requestId":"r"}""")

        assertEquals("RATE_LIMITED", e.code)
        assertEquals(429, e.httpStatus)
        assertEquals(42, e.retryAfterSec)
    }

    @Test
    fun retryAfterSecLaObjectThiKhongNem() = runTest {
        val e = httpError(429, """{"code":"RATE_LIMITED","details":{"retryAfterSec":{"x":1}}}""")

        assertEquals("RATE_LIMITED", e.code)
        assertNull(e.retryAfterSec)
        assertNull(e.detailInt("retryAfterSec"))
    }

    private suspend fun httpError(status: Int, body: String): ApiError.Http {
        try {
            apiCall<Unit> {
                throw HttpException(Response.error<Any>(status, body.toResponseBody("application/json".toMediaType())))
            }
        } catch (e: ApiError.Http) {
            return e
        }
        error("phải ném ApiError.Http")
    }
}
