import SwiftUI

@main
struct DayHocApp: App {
    /// Khi chạy test, app chỉ làm host: không đọc Keychain, không gọi API thật.
    private static let isTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    @State private var model: AppModel? = isTestHost ? nil : AppModel(env: .live())

    var body: some Scene {
        WindowGroup {
            if let model { RootView(model: model) }
        }
    }
}
