import Foundation
import Observation

/// Điều hướng gốc của app: khởi động, đăng nhập, màn sau đăng nhập, hết phiên.
@Observable @MainActor
final class AppModel {
    enum Route {
        case launching
        case login(LoginModel)
        /// Chưa có vai trò → T01c (NA-04).
        case chooseRole(UserDTO)
        /// Có vai trò → không gian của vai trò (NA-04).
        case home(UserDTO, MembershipDTO)
        /// Không tải được phiên; `offline` để chọn câu báo.
        case failed(offline: Bool)
    }

    private(set) var route: Route = .launching
    private let env: AppEnvironment

    /// Vòng nghe hết phiên do model giữ: nếu để `.task` của view giữ, view dựng lại sẽ hủy task
    /// và `AsyncStream` kết thúc, từ đó không còn nhận sự kiện nào.
    @ObservationIgnored private var expiryListener: Task<Void, Never>?

    init(env: AppEnvironment) {
        self.env = env
        expiryListener = Task { [weak self, stream = env.api.sessionExpired] in
            for await _ in stream { self?.showLogin() }
        }
    }

    /// Có token thì hỏi `/auth/me` rồi vào màn sau đăng nhập, không thì vào Đăng nhập.
    func start() async {
        guard env.auth.hasSession else { return showLogin() }
        route = .launching
        do {
            try await enter(env.auth.me())
        } catch {
            fail(error)
        }
    }

    func logout() async {
        await env.auth.logout()
        showLogin()
    }

    private func signedIn(_ user: UserDTO) async {
        do {
            try await enter(user)
        } catch {
            fail(error)
        }
    }

    // shortcut: lấy vai trò đầu tiên; NA-04 chọn theo `lastMembershipId` và chuyển vai trò.
    private func enter(_ user: UserDTO) async throws {
        let memberships = try await env.auth.memberships()
        route = memberships.items.first.map { .home(user, $0) } ?? .chooseRole(user)
    }

    private func fail(_ error: any Error) {
        // Hết phiên thì APIClient đã xóa token và phát sự kiện: về Đăng nhập.
        guard env.auth.hasSession else { return showLogin() }
        let kind = (error as? APIError)?.kind
        route = .failed(offline: kind == .offline || kind == .timeout)
    }

    private func showLogin() {
        if case .login = route { return }
        route = .login(LoginModel(auth: env.auth) { [weak self] user in
            await self?.signedIn(user)
        })
    }
}
