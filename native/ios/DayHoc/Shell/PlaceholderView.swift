import SwiftUI

/// Màn tạm sau đăng nhập (placeholder NA-04): chưa có vai trò thì báo "Chọn vai trò (đang làm)",
/// có thì chào và hiện vai trò đầu tiên. NA-04 thay bằng T01c và không gian từng vai trò.
struct PlaceholderView: View {
    let user: UserDTO
    let membership: MembershipDTO?
    let onLogout: @MainActor () async -> Void

    @State private var isLoggingOut = false
    @Environment(\.dhColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: TeachHubTokens.Dimens.spacingContent) {
            if let membership {
                Text("home.hello \(user.displayName ?? user.email)")
                    .font(.title.bold())
                Text(membership.label)
                    .foregroundStyle(colors.onSurfaceVariant)
            } else {
                Text("placeholder.chooseRole")
                    .font(.title.bold())
            }
            Text("placeholder.note")
                .font(.footnote)
                .foregroundStyle(colors.onSurfaceVariant)
            Spacer()
            DhPrimaryButton(title: "logout", isLoading: isLoggingOut) {
                isLoggingOut = true
                Task { await onLogout() }
            }
        }
        .padding(TeachHubTokens.Dimens.spacingPage)
        .dhScreen()
    }
}
