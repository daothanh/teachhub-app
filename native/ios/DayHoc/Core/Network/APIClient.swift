import Foundation

/// Client API duy nhất của app (spec Mục 3.5): gắn Bearer, `x-request-id`, `x-client-info`;
/// gặp 401 thì làm mới token một luồng rồi gửi lại; refresh bị từ chối → xóa token, báo hết phiên.
final class APIClient: Sendable {
    /// Phát mỗi khi phiên hết hạn; app nghe để về màn đăng nhập.
    let sessionExpired: AsyncStream<Void>
    private let expiredContinuation: AsyncStream<Void>.Continuation
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: any TokenStore
    private let clientInfo: String
    private let refresher = TokenRefresher()

    /// - Parameter clientInfo: `teachhub-app/<version> (ios)`.
    init(baseURL: URL, session: URLSession, tokenStore: any TokenStore, clientInfo: String) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
        self.clientInfo = clientInfo
        (sessionExpired, expiredContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    /// Gọi API và giải mã JSON trả về.
    /// - Parameter authorized: `false` cho endpoint công khai (`/auth/otp/send`, `/auth/login`,
    ///   `/auth/refresh`): không gắn Bearer, 401 không kích hoạt làm mới.
    func request<Response: Decodable>(
        _ method: String,
        _ path: String,
        body: (any Encodable & Sendable)? = nil,
        authorized: Bool = true
    ) async throws -> Response {
        let data = try await perform(method, path, body: body, authorized: authorized)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError(kind: .invalidResponse)
        }
    }

    /// Gọi API không cần đọc body (204).
    func send(
        _ method: String,
        _ path: String,
        body: (any Encodable & Sendable)? = nil,
        authorized: Bool = true
    ) async throws {
        _ = try await perform(method, path, body: body, authorized: authorized)
    }

    private func perform(
        _ method: String,
        _ path: String,
        body: (any Encodable & Sendable)?,
        authorized: Bool
    ) async throws -> Data {
        let payload = try body.map { try JSONEncoder().encode($0) }
        guard authorized else {
            return try check(await load(method, path, payload, token: nil))
        }
        let token = tokenStore.load()?.accessToken
        var result = try await load(method, path, payload, token: token)
        if result.response.statusCode == 401 {
            let fresh = try await refreshedToken(replacing: token)
            result = try await load(method, path, payload, token: fresh)
            // Token vừa làm mới vẫn bị từ chối: phiên không dùng được nữa.
            if result.response.statusCode == 401 { expire() }
        }
        return try check(result)
    }

    private func load(
        _ method: String,
        _ path: String,
        _ body: Data?,
        token: String?
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        request.setValue(UUID().uuidString.lowercased(), forHTTPHeaderField: "x-request-id")
        request.setValue(clientInfo, forHTTPHeaderField: "x-client-info")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError(kind: .invalidResponse) }
            return (data, http)
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            throw APIError(error)
        }
    }

    private func check(_ result: (data: Data, response: HTTPURLResponse)) throws -> Data {
        let status = result.response.statusCode
        guard (200..<300).contains(status) else {
            throw APIError(
                status: status,
                body: result.data,
                retryAfterHeader: result.response.value(forHTTPHeaderField: "Retry-After")
            )
        }
        return result.data
    }

    /// Access token mới thay cho `failed`. Chạy trong `TokenRefresher` nên các request 401
    /// cùng lúc chỉ gọi `/auth/refresh` một lần.
    private func refreshedToken(replacing failed: String?) async throws -> String {
        try await refresher.run { [self] in
            guard let tokens = tokenStore.load() else { throw expire() }
            // Request khác đã làm mới xong trong lúc request này chờ: dùng luôn token đó.
            if tokens.accessToken != failed { return tokens.accessToken }
            let fresh: RefreshResponse
            do {
                fresh = try await request(
                    "POST", "auth/refresh",
                    body: RefreshRequest(refreshToken: tokens.refreshToken),
                    authorized: false
                )
            } catch let error as APIError where error.status == 401 || error.status == 403 {
                // Refresh token hết hạn hoặc bị thu hồi. Chỉ xóa nếu phiên chưa đổi trong lúc chờ.
                guard tokenStore.load()?.refreshToken == tokens.refreshToken else { throw error }
                throw expire()
            }
            // Đăng xuất hoặc đăng nhập mới trong lúc chờ: bỏ kết quả, không làm phiên cũ sống lại.
            guard tokenStore.load()?.refreshToken == tokens.refreshToken else {
                throw APIError(kind: .http, status: 401, code: "UNAUTHENTICATED")
            }
            // Lưu lỗi thì request này vẫn dùng token mới; lần mở app sau có thể phải đăng nhập lại.
            try? tokenStore.save(Tokens(accessToken: fresh.accessToken, refreshToken: fresh.refreshToken))
            return fresh.accessToken
        }
    }

    /// Xóa token và báo hết phiên; trả lỗi để nơi gọi ném tiếp.
    @discardableResult
    private func expire() -> APIError {
        tokenStore.clear()
        expiredContinuation.yield()
        return APIError(kind: .http, status: 401, code: "UNAUTHENTICATED")
    }
}
