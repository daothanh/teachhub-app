// DTO viết tay theo teachhub-backend/contracts/openapi.json (nhóm auth, me).

/// Body `POST /v1/auth/otp/send`.
struct SendOtpRequest: Encodable, Sendable {
    let email: String
}

/// Body `POST /v1/auth/login`.
struct LoginRequest: Encodable, Sendable {
    let method = "email_otp"
    let email: String
    let code: String
}

/// 200 của `POST /v1/auth/login`.
struct LoginResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: UserDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

/// Body `POST /v1/auth/refresh`.
struct RefreshRequest: Encodable, Sendable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

/// 200 của `POST /v1/auth/refresh`.
struct RefreshResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

/// Schema `User` (`GET /v1/auth/me`).
struct UserDTO: Decodable, Equatable, Sendable {
    let id: String
    let email: String
    let displayName: String?
    let permissions: [String]
}

/// Schema `Membership`.
struct MembershipDTO: Decodable, Equatable, Sendable {
    let id: String
    /// `tenant_owner` | `parent` | `student`.
    let role: String
    /// Nhãn hiển thị do API trả, vd "Giáo viên · Cô Lan".
    let label: String
    let tenantId: String?
    let studentId: String?
}

/// 200 của `GET /v1/me/memberships`.
struct MembershipsDTO: Decodable, Sendable {
    let items: [MembershipDTO]
    let lastMembershipId: String?
}
