import Foundation
import Security

struct Tokens: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
}

/// Nơi giữ token phiên. Giao thức để test thay bằng bản trong bộ nhớ.
protocol TokenStore: Sendable {
    func load() -> Tokens?
    func save(_ tokens: Tokens) throws
    func clear()
}

struct KeychainError: Error {
    let status: OSStatus
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

    /// Cập nhật tại chỗ, chỉ thêm khi chưa có: không có lúc nào Keychain trống giữa hai bước.
    func save(_ tokens: Tokens) throws {
        let data = try JSONEncoder().encode(tokens)
        var status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(query as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
