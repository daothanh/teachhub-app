import Foundation
import Security

struct Tokens: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
}

/// Nơi giữ token phiên. Giao thức để test thay bằng bản trong bộ nhớ.
protocol TokenStore: Sendable {
    func load() -> Tokens?
    func save(_ tokens: Tokens)
    func clear()
}

/// Lưu token trong Keychain: chỉ đọc được sau lần mở khóa đầu, không theo bản sao lưu sang máy khác.
struct KeychainTokenStore: TokenStore {
    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "vn.dayhoc.app.session",
            kSecAttrAccount as String: "tokens",
        ]
    }

    func load() -> Tokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return try? JSONDecoder().decode(Tokens.self, from: data)
    }

    func save(_ tokens: Tokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        clear()
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        assert(status == errSecSuccess, "Không lưu được token vào Keychain: \(status)")
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
