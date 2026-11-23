import Foundation
import os
@testable import DayHoc

/// Phản hồi giả của máy chủ.
struct Stub: Sendable {
    var status: Int
    var json = ""

    static let noContent = Stub(status: 204)

    static func error(_ status: Int, _ code: String, retryAfterSec: Int? = nil) -> Stub {
        let details = retryAfterSec.map { #","details":{"retryAfterSec":\#($0)}"# } ?? ""
        return Stub(status: status, json: #"{"code":"\#(code)","message":"","requestId":"t"\#(details)}"#)
    }
}

/// Máy chủ giả theo host: mỗi test một host riêng nên các test chạy song song không lẫn nhau.
final class MockServer: Sendable {
    let host = "\(UUID().uuidString.lowercased()).test"
    private let handler: @Sendable (URLRequest) -> Stub
    private let log = OSAllocatedUnfairLock<[URLRequest]>(initialState: [])

    init(handler: @escaping @Sendable (URLRequest) -> Stub) {
        self.handler = handler
        MockURLProtocol.servers.withLock { $0[host] = self }
    }

    var requests: [URLRequest] { log.withLock { $0 } }

    func requests(to path: String) -> [URLRequest] {
        requests.filter { $0.url?.path == "/v1/\(path)" }
    }

    func makeClient(tokenStore: any TokenStore) -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return APIClient(
            baseURL: URL(string: "https://\(host)/v1")!,
            session: URLSession(configuration: configuration),
            tokenStore: tokenStore,
            clientInfo: "teachhub-app/test (ios)"
        )
    }

    fileprivate func respond(to request: URLRequest) -> Stub {
        log.withLock { $0.append(request) }
        return handler(request)
    }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static let servers = OSAllocatedUnfairLock<[String: MockServer]>(initialState: [:])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let request = request
        guard let url = request.url,
              let server = Self.servers.withLock({ $0[url.host() ?? ""] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }
        // Trả lời trễ một chút để các request song song thật sự chồng lên nhau.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            let stub = server.respond(to: request)
            let response = HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: nil, headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: Data(stub.json.utf8))
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
}

/// TokenStore trong bộ nhớ thay Keychain.
final class InMemoryTokenStore: TokenStore {
    private let state: OSAllocatedUnfairLock<Tokens?>

    init(_ tokens: Tokens? = nil) {
        state = OSAllocatedUnfairLock(initialState: tokens)
    }

    func load() -> Tokens? { state.withLock { $0 } }
    func save(_ tokens: Tokens) { state.withLock { $0 = tokens } }
    func clear() { state.withLock { $0 = nil } }
}

extension URLRequest {
    /// Body JSON; URLProtocol nhận body qua stream chứ không qua `httpBody`.
    var jsonBody: [String: String] {
        guard let stream = httpBodyStream else { return [:] }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
}

let userJSON = #"{"id":"019a8f3e-7c1b-7d2a-9b3e-5f6a7b8c9d0e","email":"co.lan@example.com","displayName":"Cô Lan","permissions":[]}"#
