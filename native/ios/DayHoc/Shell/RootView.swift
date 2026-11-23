import SwiftUI

/// Gốc giao diện: đổi màn theo `AppModel.route`.
struct RootView: View {
    let model: AppModel

    var body: some View {
        content
            .dhTheme()
            .task { await model.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.route {
        case .launching:
            ProgressView().dhScreen()
        case .login(let login):
            LoginView(model: login)
        case .chooseRole(let user):
            PlaceholderView(user: user, membership: nil) { await model.logout() }
        case .home(let user, let membership):
            PlaceholderView(user: user, membership: membership) { await model.logout() }
        case .failed(let offline):
            VStack(spacing: TeachHubTokens.Dimens.spacingContent) {
                Text(offline ? "error.offline" : "login.unavailable")
                    .multilineTextAlignment(.center)
                DhPrimaryButton(title: "retry") {
                    Task { await model.start() }
                }
            }
            .padding(TeachHubTokens.Dimens.spacingPage)
            .dhScreen()
        }
    }
}
