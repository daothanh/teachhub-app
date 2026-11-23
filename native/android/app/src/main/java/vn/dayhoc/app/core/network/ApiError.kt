package vn.dayhoc.app.core.network

import java.io.IOException
import java.io.InterruptedIOException
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull
import retrofit2.HttpException

/** Lỗi gọi API có kiểu (Technical Spec Mục 5.6). Màn hình đổi sang chuỗi tiếng Việt theo [Http.code]. */
sealed class ApiError : Exception() {
    /** API trả lỗi. [code] lấy từ body (`contracts/error_codes.json`), rỗng nếu body sai định dạng. */
    data class Http(
        val code: String,
        val httpStatus: Int,
        val details: JsonObject = JsonObject(emptyMap()),
        val retryAfterSec: Int? = null,
    ) : ApiError() {
        fun detailInt(key: String): Int? = (details[key] as? JsonPrimitive)?.intOrNull
    }

    /** Không kết nối được (mất mạng, DNS, từ chối kết nối). */
    data object Network : ApiError()

    /** Kết nối được nhưng quá thời gian chờ. */
    data object Timeout : ApiError()

    /** Body thành công nhưng sai hợp đồng (không giải mã được). */
    data object InvalidResponse : ApiError()

    companion object {
        // shortcut: chỉ khai mã cần cho đăng nhập; sinh đủ từ error_codes.json bằng script khi làm các feature sau.
        const val OTP_INVALID = "OTP_INVALID"
        const val OTP_LOCKED = "OTP_LOCKED"
        const val RATE_LIMITED = "RATE_LIMITED"
        const val SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE"
        const val UNAUTHENTICATED = "UNAUTHENTICATED"
    }
}

@Serializable
private data class ErrorBody(val code: String = "", val details: JsonObject = JsonObject(emptyMap()))

private val errorJson = Json { ignoreUnknownKeys = true }

/** Chạy một lời gọi Retrofit, đổi lỗi HTTP/mạng thành [ApiError]. */
suspend fun <T> apiCall(block: suspend () -> T): T =
    try {
        block()
    } catch (e: HttpException) {
        val response = e.response()
        // Body lỗi đọc hỏng hoặc sai định dạng không được che mất mã HTTP.
        val body = try {
            response?.errorBody()?.string()?.let { errorJson.decodeFromString<ErrorBody>(it) }
        } catch (ce: CancellationException) {
            throw ce
        } catch (parseError: Exception) {
            null
        }
        throw ApiError.Http(
            code = body?.code.orEmpty(),
            httpStatus = e.code(),
            details = body?.details ?: JsonObject(emptyMap()),
            retryAfterSec = (body?.details?.get("retryAfterSec") as? JsonPrimitive)?.intOrNull
                ?: response?.headers()?.get("Retry-After")?.toIntOrNull(),
        )
    } catch (e: SerializationException) {
        throw ApiError.InvalidResponse
    } catch (e: InterruptedIOException) {
        throw ApiError.Timeout
    } catch (e: IOException) {
        throw ApiError.Network
    }
