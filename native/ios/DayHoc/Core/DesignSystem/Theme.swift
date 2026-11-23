import SwiftUI

/// Bộ màu Light/Dark lấy từ `TeachHubTokens` (sinh từ token Figma). Màn hình đọc qua
/// `@Environment(\.dhColors)`, không viết màu rời.
struct DhColors: Sendable {
    let primary: Color
    let onPrimary: Color
    let secondary: Color
    let surface: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let surfaceContainerHighest: Color
    let outline: Color
    let error: Color
    let errorContainer: Color
    let onErrorContainer: Color
    let placeholder: Color
    let scaffoldBackground: Color

    static let light = DhColors(
        primary: TeachHubTokens.Light.primary,
        onPrimary: TeachHubTokens.Light.onPrimary,
        secondary: TeachHubTokens.Light.secondary,
        surface: TeachHubTokens.Light.surface,
        onSurface: TeachHubTokens.Light.onSurface,
        onSurfaceVariant: TeachHubTokens.Light.onSurfaceVariant,
        surfaceContainerHighest: TeachHubTokens.Light.surfaceContainerHighest,
        outline: TeachHubTokens.Light.outline,
        error: TeachHubTokens.Light.error,
        errorContainer: TeachHubTokens.Light.errorContainer,
        onErrorContainer: TeachHubTokens.Light.onErrorContainer,
        placeholder: TeachHubTokens.Light.placeholderColor,
        scaffoldBackground: TeachHubTokens.Light.scaffoldBackground
    )

    static let dark = DhColors(
        primary: TeachHubTokens.Dark.primary,
        onPrimary: TeachHubTokens.Dark.onPrimary,
        secondary: TeachHubTokens.Dark.secondary,
        surface: TeachHubTokens.Dark.surface,
        onSurface: TeachHubTokens.Dark.onSurface,
        onSurfaceVariant: TeachHubTokens.Dark.onSurfaceVariant,
        surfaceContainerHighest: TeachHubTokens.Dark.surfaceContainerHighest,
        outline: TeachHubTokens.Dark.outline,
        error: TeachHubTokens.Dark.error,
        errorContainer: TeachHubTokens.Dark.errorContainer,
        onErrorContainer: TeachHubTokens.Dark.onErrorContainer,
        placeholder: TeachHubTokens.Dark.placeholderColor,
        scaffoldBackground: TeachHubTokens.Dark.scaffoldBackground
    )
}

extension EnvironmentValues {
    @Entry var dhColors: DhColors = .light
}

extension View {
    /// Chọn bộ màu theo chế độ sáng/tối của hệ thống. Gắn một lần ở gốc app.
    func dhTheme() -> some View { modifier(DhThemeModifier()) }

    /// Nền màn hình (`scaffoldBackground`) phủ cả vùng an toàn.
    func dhScreen() -> some View { modifier(DhScreenModifier()) }
}

private struct DhThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let colors: DhColors = colorScheme == .dark ? .dark : .light
        content
            .environment(\.dhColors, colors)
            .tint(colors.secondary)
    }
}

private struct DhScreenModifier: ViewModifier {
    @Environment(\.dhColors) private var colors

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colors.scaffoldBackground.ignoresSafeArea())
            .foregroundStyle(colors.onSurface)
    }
}
