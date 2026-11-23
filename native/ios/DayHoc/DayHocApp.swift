import SwiftUI

@main
struct DayHocApp: App {
    @State private var model = AppModel(env: .live())

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}
