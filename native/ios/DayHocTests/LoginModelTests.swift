import Foundation
import Testing
@testable import DayHoc

@MainActor
struct LoginModelTests {
    private let store = InMemoryTokenStore()

    private func makeModel(
        _ server: MockServer,
        now: @escaping () -> Date = { .now },
        onSignedIn: @escaping @MainActor (UserDTO) async -> Void = { _ in }
    ) -> LoginModel {
        let auth = AuthRepository(api: server.makeClient(tokenStore: store), tokenStore: store)
        let model = LoginModel(auth: auth, now: now, onSignedIn: onSignedIn)
        model.email = " Co.Lan@Example.com "
        return model
    }

    @Test func sendCodeMovesToOtpStep() async {
        let server = MockServer { _ in .noContent }
        let model = makeModel(server)

        await model.sendCode()

        #expect(model.sentTo == "co.lan@example.com")
        #expect(model.failure == nil)
        #expect(server.requests(to: "auth/otp/send").first?.jsonBody == ["email": "co.lan@example.com"])
    }

    @Test func wrongCodeShowsError() async {
        let server = MockServer { request in
            request.url?.path == "/v1/auth/login" ? .error(401, "OTP_INVALID") : .noContent
        }
        let model = makeModel(server)
        await model.sendCode()

        model.enterCode("12a3456")
        await model.verify()

        #expect(model.failure == .otpInvalid)
        #expect(model.sentTo != nil)
        #expect(server.requests(to: "auth/login").first?.jsonBody
            == ["method": "email_otp", "email": "co.lan@example.com", "code": "123456"])
        // Endpoint công khai: 401 không kích hoạt làm mới token.
        #expect(server.requests(to: "auth/refresh").isEmpty)
    }

    @Test func resendBlockedFor60Seconds() async {
        let server = MockServer { _ in .noContent }
        var clock = Date(timeIntervalSince1970: 1_000)
        let model = makeModel(server, now: { clock })
        await model.sendCode()

        clock += 59
        #expect(model.secondsUntilResend(at: clock) == 1)
        await model.resend()
        #expect(server.requests(to: "auth/otp/send").count == 1)

        clock += 1
        await model.resend()
        #expect(server.requests(to: "auth/otp/send").count == 2)
    }

    @Test func lockedOtpWaitsRetryAfter() async {
        let server = MockServer { request in
            request.url?.path == "/v1/auth/login" ? .error(429, "OTP_LOCKED", retryAfterSec: 900) : .noContent
        }
        let clock = Date(timeIntervalSince1970: 1_000)
        let model = makeModel(server, now: { clock })
        await model.sendCode()

        model.enterCode("123456")
        await model.verify()

        #expect(model.isLocked(at: clock + 899))
        #expect(!model.isLocked(at: clock + 900))
        #expect(model.code.isEmpty)
    }

    @Test func correctCodeSavesTokensAndSignsIn() async {
        let server = MockServer { request in
            request.url?.path == "/v1/auth/login"
                ? Stub(status: 200, json: #"{"access_token":"a1","refresh_token":"r1","expires_in":900,"user":\#(userJSON)}"#)
                : .noContent
        }
        var signedIn: UserDTO?
        let model = makeModel(server, onSignedIn: { signedIn = $0 })
        await model.sendCode()

        model.enterCode("123456")
        await model.verify()

        #expect(signedIn?.displayName == "Cô Lan")
        #expect(store.load() == Tokens(accessToken: "a1", refreshToken: "r1"))
    }
}
