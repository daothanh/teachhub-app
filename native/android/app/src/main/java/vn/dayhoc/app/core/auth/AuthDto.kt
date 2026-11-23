package vn.dayhoc.app.core.auth

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// DTO viết tay theo teachhub-backend/contracts/openapi.json (tag auth, me).

@Serializable
data class SendOtpRequest(val email: String)

@Serializable
data class LoginRequest(val method: String, val email: String, val code: String)

@Serializable
data class RefreshRequest(@SerialName("refresh_token") val refreshToken: String)

@Serializable
data class LoginResponse(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String,
    @SerialName("expires_in") val expiresIn: Long,
    val user: UserDto,
)

@Serializable
data class TokenResponse(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String,
    @SerialName("expires_in") val expiresIn: Long,
)

@Serializable
data class UserDto(
    val id: String,
    val email: String,
    val displayName: String?,
    val permissions: List<String>,
)

@Serializable
data class MembershipDto(
    val id: String,
    /** `tenant_owner` | `parent` | `student` */
    val role: String,
    val label: String,
    val tenantId: String?,
    val studentId: String?,
)

@Serializable
data class MembershipsResponse(
    val items: List<MembershipDto>,
    val lastMembershipId: String?,
)
