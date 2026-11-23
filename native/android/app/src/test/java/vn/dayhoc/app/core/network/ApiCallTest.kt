package vn.dayhoc.app.core.network

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.SerializationException
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Test

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
}
