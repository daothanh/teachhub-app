/// Làm mới token một luồng: các request cùng gặp 401 chờ chung một `Task`,
/// nên chỉ có một lần gọi `/auth/refresh`.
actor TokenRefresher {
    private var inFlight: Task<String, any Error>?

    /// Chạy `refresh` nếu chưa có lượt nào đang chạy, không thì chờ lượt đang chạy.
    func run(_ refresh: @escaping @Sendable () async throws -> String) async throws -> String {
        if let inFlight { return try await inFlight.value }
        let task = Task(operation: refresh)
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}
