import Foundation

/// Các phụ thuộc dùng chung của app, tạo một lần ở `DayHocApp` và truyền qua init (ADR Mục 3).
struct AppEnvironment: Sendable {
    let api: APIClient
    let auth: AuthRepository

    init(api: APIClient, tokenStore: any TokenStore) {
        self.api = api
        auth = AuthRepository(api: api, tokenStore: tokenStore)
    }

    /// Bản chạy thật: `API_URL` lấy từ Info.plist (giá trị đặt trong `Config/*.xcconfig`).
    static func live() -> AppEnvironment {
        let info = Bundle.main.infoDictionary ?? [:]
        guard let raw = info["API_URL"] as? String, let baseURL = URL(string: raw) else {
            fatalError("Thiếu API_URL trong Info.plist, xem Config/*.xcconfig")
        }
        let version = info["CFBundleShortVersionString"] as? String ?? "0"
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        let tokenStore = KeychainTokenStore()
        let api = APIClient(
            baseURL: baseURL,
            session: URLSession(configuration: configuration),
            tokenStore: tokenStore,
            clientInfo: "teachhub-app/\(version) (ios)"
        )
        return AppEnvironment(api: api, tokenStore: tokenStore)
    }
}
