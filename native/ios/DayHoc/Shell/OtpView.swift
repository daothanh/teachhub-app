import SwiftUI

/// [T01a] Nhập mã OTP: 6 số, gửi lại sau 60 giây, báo sai mã và tạm khóa theo mã lỗi backend.
struct OtpView: View {
    let model: LoginModel
    @Environment(\.dhColors) private var colors

    var body: some View {
        // Vẽ lại mỗi giây cho hai bộ đếm ngược; model chỉ giữ mốc thời gian.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
        }
        .dhScreen()
        .navigationTitle("otp.title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isVerifying)
    }

    private func content(now: Date) -> some View {
        let locked = model.isLocked(at: now)
        return VStack(alignment: .leading, spacing: TeachHubTokens.Dimens.spacingContent) {
            if locked { lockedBanner }
            Text("otp.heading")
                .font(.title2.bold())
            Text("otp.sentTo \(model.sentTo ?? "")")
                .foregroundStyle(colors.onSurfaceVariant)
            DhTextField(label: "otp.codeLabel", text: codeBinding, error: model.failure?.message)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .disabled(locked || model.isVerifying)
            status(now: now, locked: locked)
                .frame(maxWidth: .infinity)
            Spacer()
            DhPrimaryButton(
                title: locked ? "otp.locked" : "otp.confirm",
                loadingTitle: "otp.verifying",
                isLoading: model.isVerifying,
                action: verify
            )
            .disabled(locked || model.code.count < 6)
        }
        .padding(TeachHubTokens.Dimens.spacingPage)
    }

    /// Đủ 6 số thì tự xác nhận như app Flutter.
    private var codeBinding: Binding<String> {
        Binding(
            get: { model.code },
            set: {
                model.enterCode($0)
                if model.code.count == 6 { verify() }
            }
        )
    }

    @ViewBuilder
    private func status(now: Date, locked: Bool) -> some View {
        let caption = Font.footnote
        if locked {
            Text("otp.retryIn \(Self.mmss(model.secondsUntilUnlock(at: now)))")
                .font(caption)
                .foregroundStyle(colors.onSurfaceVariant)
        } else if model.secondsUntilResend(at: now) > 0 {
            Text("otp.resendIn \(Self.mmss(model.secondsUntilResend(at: now)))")
                .font(caption)
                .foregroundStyle(colors.onSurfaceVariant)
        } else {
            Button("login.resend") {
                Task { await model.resend() }
            }
            .font(caption.weight(.semibold))
            .disabled(model.isSending)
        }
    }

    /// Feedback/Banner Error của DS (B24).
    private var lockedBanner: some View {
        VStack(alignment: .leading, spacing: TeachHubTokens.Dimens.spacingInline) {
            Text("otp.lockedTitle")
                .font(.subheadline.bold())
                .foregroundStyle(colors.onErrorContainer)
            Text("otp.lockedBody")
                .font(.footnote)
                .foregroundStyle(colors.onSurfaceVariant)
        }
        .padding(TeachHubTokens.Dimens.spacingContent)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.errorContainer, in: RoundedRectangle(cornerRadius: TeachHubTokens.Dimens.cardRadius))
    }

    private func verify() {
        Task { await model.verify() }
    }

    private static func mmss(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }
}
