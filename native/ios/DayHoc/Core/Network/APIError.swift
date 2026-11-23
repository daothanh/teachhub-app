import Foundation

/// Lỗi gọi API (spec Mục 5.6). Màn hình đổi sang chuỗi tiếng Việt theo `code`;
/// `message` của server chỉ là dự phòng nên không giữ.
struct APIError: Error, Equatable {
    enum Kind: Equatable {
        /// Mất mạng, không tới được máy chủ.
        case offline
        case timeout
        /// Máy chủ trả mã HTTP lỗi.
        case http
        /// Phản hồi sai hình dạng hợp đồng.
        case invalidResponse
    }

    let kind: Kind
    /// HTTP status; `nil` khi không có phản hồi.
    var status: Int?
    /// `code` trong body lỗi, xem `teachhub-backend/contracts/error_codes.json`.
    var code: String?
    /// Thời gian chờ của 429: `details.retryAfterSec`, không có thì header `Retry-After`.
    var retryAfterSec: Int?

    init(kind: Kind, status: Int? = nil, code: String? = nil, retryAfterSec: Int? = nil) {
        self.kind = kind
        self.status = status
        self.code = code
        self.retryAfterSec = retryAfterSec
    }

    init(status: Int, body: Data, retryAfterHeader: String?) {
        let parsed = try? JSONDecoder().decode(ErrorBody.self, from: body)
        self.init(
            kind: .http,
            status: status,
            code: parsed?.code,
            retryAfterSec: parsed?.details?.retryAfterSec ?? retryAfterHeader.flatMap { Int($0) }
        )
    }

    init(_ error: URLError) {
        self.init(kind: error.code == .timedOut ? .timeout : .offline)
    }
}

/// `ErrorBody` trong openapi.json; chỉ đọc các trường app dùng.
private struct ErrorBody: Decodable {
    struct Details: Decodable {
        let retryAfterSec: Int?
    }

    let code: String
    let details: Details?
}
