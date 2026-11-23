import Foundation
import Testing
@testable import DayHoc

struct APIClientTests {
    @Test func concurrent401sRefreshOnceAndAllSucceed() async throws {
        let server = MockServer { request in
            if request.url?.path == "/v1/auth/refresh" {
                return Stub(status: 200, json: #"{"access_token":"new","refresh_token":"r2","expires_in":900}"#)
            }
            return request.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                ? Stub(status: 200, json: userJSON)
                : .error(401, "TOKEN_EXPIRED")
        }
        let store = InMemoryTokenStore(Tokens(accessToken: "old", refreshToken: "r1"))
        let api = server.makeClient(tokenStore: store)

        async let first: UserDTO = api.request("GET", "auth/me")
        async let second: UserDTO = api.request("GET", "auth/me")
        async let third: UserDTO = api.request("GET", "auth/me")
        let users = try await [first, second, third]

        #expect(users.allSatisfy { $0.email == "co.lan@example.com" })
        let refreshes = server.requests(to: "auth/refresh")
        #expect(refreshes.count == 1)
        #expect(refreshes.first?.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(refreshes.first?.jsonBody == ["refresh_token": "r1"])
        #expect(store.load() == Tokens(accessToken: "new", refreshToken: "r2"))
        #expect(server.requests.allSatisfy {
            $0.value(forHTTPHeaderField: "x-request-id") != nil
                && $0.value(forHTTPHeaderField: "x-client-info") == "teachhub-app/test (ios)"
        })
    }

    @Test func rejectedRefreshClearsTokensAndExpiresSession() async throws {
        let server = MockServer { _ in .error(401, "UNAUTHENTICATED") }
        let store = InMemoryTokenStore(Tokens(accessToken: "old", refreshToken: "revoked"))
        let api = server.makeClient(tokenStore: store)
        var expired = api.sessionExpired.makeAsyncIterator()

        await #expect(throws: APIError.self) {
            let _: UserDTO = try await api.request("GET", "auth/me")
        }

        #expect(store.load() == nil)
        #expect(await expired.next() != nil)
        #expect(server.requests(to: "auth/refresh").count == 1)
    }

    @Test func refreshServerErrorKeepsSession() async throws {
        let server = MockServer { request in
            request.url?.path == "/v1/auth/refresh" ? .error(500, "INTERNAL") : .error(401, "TOKEN_EXPIRED")
        }
        let tokens = Tokens(accessToken: "old", refreshToken: "r1")
        let store = InMemoryTokenStore(tokens)
        let api = server.makeClient(tokenStore: store)

        await #expect(throws: APIError.self) {
            let _: UserDTO = try await api.request("GET", "auth/me")
        }

        #expect(store.load() == tokens)
    }

    @Test func logoutDuringRefreshDoesNotResurrectSession() async throws {
        let store = InMemoryTokenStore(Tokens(accessToken: "old", refreshToken: "r1"))
        let server = MockServer { request in
            guard request.url?.path == "/v1/auth/refresh" else { return .error(401, "TOKEN_EXPIRED") }
            store.clear()  // người dùng bấm Đăng xuất khi refresh chưa trả về
            return Stub(status: 200, json: #"{"access_token":"new","refresh_token":"r2","expires_in":900}"#)
        }
        let api = server.makeClient(tokenStore: store)

        await #expect(throws: APIError.self) {
            let _: UserDTO = try await api.request("GET", "auth/me")
        }

        #expect(store.load() == nil)
    }
}
