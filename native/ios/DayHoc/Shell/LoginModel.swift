import Foundation
import Observation

/// State của [T01] Đăng nhập và [T01a] Nhập mã OTP.
@Observable @MainActor
final class LoginModel {
    enum Failure: Equatable {
        case invalidEmail
        case otpInvalid
        case rateLimited
        case offline
        case unavailable
        case generic
    }

    /// Gửi lại OTP: 60 giây/lần (spec Mục 5.2a).
    static let resendInterval: TimeInterval = 60
    /// Khóa khi server không trả `retryAfterSec`: 15 phút (spec Mục 5.2a).
    private static let defaultLock: TimeInterval = 15 * 60

    var email = ""
    private(set) var code = ""
    /// Email đã nhận mã; khác `nil` nghĩa là đang ở bước nhập OTP.
    private(set) var sentTo: String?
    private(set) var isSending = false
    private(set) var isVerifying = false
    var failure: Failure?
    private(set) var resendAvailableAt: Date?
    private(set) var lockedUntil: Date?

    private let auth: AuthRepository
    private let now: () -> Date
    private let onSignedIn: @MainActor (UserDTO) async -> Void

    /// - Parameter now: đồng hồ, tiêm vào để test đếm ngược không phải chờ thật.
    init(auth: AuthRepository, now: @escaping () -> Date = { .now }, onSignedIn: @escaping @MainActor (UserDTO) async -> Void) {
        self.auth = auth
        self.now = now
        self.onSignedIn = onSignedIn
    }

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isEmailValid: Bool {
        normalizedEmail.wholeMatch(of: #/[^@\s]+@[^@\s]+\.[^@\s]+/#) != nil
    }

    func sendCode() async {
        guard isEmailValid else {
            failure = .invalidEmail
            return
        }
        guard !isSending else { return }
        let target = normalizedEmail
        isSending = true
        failure = nil
        defer { isSending = false }
        do {
            try await auth.sendOtp(email: target)
            sentTo = target
            code = ""
            resendAvailableAt = now() + Self.resendInterval
        } catch {
            failure = Self.failure(for: error)
            if let wait = (error as? APIError)?.retryAfterSec {
                resendAvailableAt = now() + TimeInterval(wait)
            }
        }
    }

    /// Gửi lại mã; bỏ qua khi chưa hết 60 giây.
    func resend() async {
        guard sentTo != nil, secondsUntilResend(at: now()) == 0 else { return }
        await sendCode()
    }

    /// Chỉ giữ chữ số, tối đa 6.
    func enterCode(_ value: String) {
        code = String(value.filter { $0.isASCII && $0.isNumber }.prefix(6))
        if failure == .otpInvalid { failure = nil }
    }

    func verify() async {
        guard let sentTo, code.count == 6, !isVerifying, !isLocked(at: now()) else { return }
        isVerifying = true
        failure = nil
        defer { isVerifying = false }
        do {
            let user = try await auth.login(email: sentTo, code: code)
            await onSignedIn(user)
        } catch let error as APIError where error.code == "OTP_LOCKED" {
            lockedUntil = now() + (error.retryAfterSec.map(TimeInterval.init) ?? Self.defaultLock)
            code = ""
        } catch {
            failure = Self.failure(for: error)
        }
    }

    /// Quay lại bước nhập email.
    func changeEmail() {
        sentTo = nil
        code = ""
        failure = nil
        lockedUntil = nil
    }

    func secondsUntilResend(at date: Date) -> Int { Self.seconds(until: resendAvailableAt, from: date) }
    func secondsUntilUnlock(at date: Date) -> Int { Self.seconds(until: lockedUntil, from: date) }
    func isLocked(at date: Date) -> Bool { secondsUntilUnlock(at: date) > 0 }

    private static func seconds(until deadline: Date?, from date: Date) -> Int {
        guard let deadline else { return 0 }
        return max(0, Int(deadline.timeIntervalSince(date).rounded(.up)))
    }

    // shortcut: so `code` bằng chuỗi; đổi sang hằng số sinh từ error_codes.json khi có script sinh Swift.
    private static func failure(for error: any Error) -> Failure {
        guard let error = error as? APIError else { return .generic }
        switch (error.kind, error.code) {
        case (.offline, _), (.timeout, _): return .offline
        case (_, "OTP_INVALID"): return .otpInvalid
        case (_, "RATE_LIMITED"), (_, "OTP_LOCKED"): return .rateLimited
        case (_, "VALIDATION_FAILED"): return .invalidEmail
        default: return (error.status ?? 0) >= 500 ? .unavailable : .generic
        }
    }
}
