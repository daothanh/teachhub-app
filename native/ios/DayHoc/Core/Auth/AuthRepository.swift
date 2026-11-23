/// Đăng nhập email OTP và phiên (spec Mục 5.2a).
struct AuthRepository: Sendable {
    let api: APIClient
    let tokenStore: any TokenStore

    var hasSession: Bool { tokenStore.load() != nil }

    /// Gửi mã 6 số tới email. Server giới hạn 60 giây/lần, 5 lần/giờ (429 `RATE_LIMITED`).
    func sendOtp(email: String) async throws {
        try await api.send("POST", "auth/otp/send", body: SendOtpRequest(email: email), authorized: false)
    }

    /// Đăng nhập (email chưa có tài khoản thì là đăng ký) và lưu token.
    func login(email: String, code: String) async throws -> UserDTO {
        let response: LoginResponse = try await api.request(
            "POST", "auth/login",
            body: LoginRequest(email: email, code: code),
            authorized: false
        )
        try tokenStore.save(Tokens(accessToken: response.accessToken, refreshToken: response.refreshToken))
        return response.user
    }

    func me() async throws -> UserDTO {
        try await api.request("GET", "auth/me")
    }

    func memberships() async throws -> MembershipsDTO {
        try await api.request("GET", "me/memberships")
    }

    /// Thu hồi phiên ở server rồi xóa token trên máy; lỗi mạng không chặn đăng xuất.
    func logout() async {
        try? await api.send("POST", "auth/logout")
        tokenStore.clear()
    }
}
