import SwiftUI

/// Ô nhập của DS: nhãn phía trên, viền `outline`, bo `fieldRadius`; có lỗi thì viền và
/// dòng chú thích đổi sang `error`. Kiểu bàn phím, `textContentType`… gắn từ ngoài.
struct DhTextField: View {
    let label: LocalizedStringKey
    @Binding var text: String
    /// Tra bản dịch rồi hiện nguyên văn: `LocalizedStringKey` hiểu markdown và tô `ten@email.com` thành link.
    var prompt: LocalizedStringResource?
    var helper: LocalizedStringKey?
    var error: LocalizedStringKey?

    @Environment(\.dhColors) private var colors

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: TeachHubTokens.Dimens.fieldRadius)
        VStack(alignment: .leading, spacing: TeachHubTokens.Dimens.spacingInline) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(colors.onSurface)
            TextField(label, text: $text, prompt: prompt.map { Text(String(localized: $0)).foregroundStyle(colors.placeholder) })
                .padding(TeachHubTokens.Dimens.spacingContent)
                .foregroundStyle(colors.onSurface)
                .background(colors.surface, in: shape)
                .overlay(shape.stroke(error == nil ? colors.outline : colors.error))
            if let message = error ?? helper {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(error == nil ? colors.onSurfaceVariant : colors.error)
            }
        }
    }
}
