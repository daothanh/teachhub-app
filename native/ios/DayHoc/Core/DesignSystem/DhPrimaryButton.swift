import SwiftUI

/// Nút chính của DS: nền lime (`primary`), chữ `onPrimary`, bo `buttonRadius`.
/// Đang chạy thì giữ nền lime, hiện spinner và `loadingTitle`; tắt bằng `.disabled(_:)`.
struct DhPrimaryButton: View {
    let title: LocalizedStringKey
    var loadingTitle: LocalizedStringKey?
    var isLoading = false
    let action: () -> Void

    /// Vùng chạm tối thiểu theo HIG; DS chưa có token chiều cao nút.
    private static let minHeight: CGFloat = 48

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dhColors) private var colors

    var body: some View {
        let active = isEnabled || isLoading
        Button(action: action) {
            HStack(spacing: TeachHubTokens.Dimens.spacingControl) {
                if isLoading {
                    ProgressView().tint(colors.onPrimary)
                }
                Text(isLoading ? loadingTitle ?? title : title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: Self.minHeight)
            .padding(.horizontal, TeachHubTokens.Dimens.spacingPage)
            .foregroundStyle(active ? colors.onPrimary : colors.onSurfaceVariant)
            .background(
                active ? colors.primary : colors.surfaceContainerHighest,
                in: RoundedRectangle(cornerRadius: TeachHubTokens.Dimens.buttonRadius)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
