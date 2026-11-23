import SwiftUI

/// [T01] Đăng nhập: nhập email, gửi mã. NA-03 chỉ có email OTP; Google/Apple, hình minh họa
/// và liên kết Điều khoản làm ở task sau.
struct LoginView: View {
    @Bindable var model: LoginModel
    @Environment(\.dhColors) private var colors

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TeachHubTokens.Dimens.spacingContent) {
                    Text("app.name")
                        .font(.largeTitle.bold())
                    Text("login.slogan")
                        .font(.title2.bold())
                    Text("login.tagline")
                        .foregroundStyle(colors.onSurfaceVariant)
                        .padding(.bottom, TeachHubTokens.Dimens.spacingSection)
                    DhTextField(
                        label: "login.email",
                        text: $model.email,
                        prompt: "login.emailHint",
                        helper: "login.emailHelper",
                        error: model.failure == .invalidEmail ? model.failure?.message : nil
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit(send)
                    .disabled(model.isSending)
                    DhPrimaryButton(
                        title: "login.sendOtp",
                        loadingTitle: "login.sending",
                        isLoading: model.isSending,
                        action: send
                    )
                    .disabled(!model.isEmailValid)
                    if let failure = model.failure, failure != .invalidEmail {
                        Text(failure.message)
                            .font(.footnote)
                            .foregroundStyle(colors.error)
                    }
                    Text("login.terms")
                        .font(.footnote)
                        .foregroundStyle(colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(TeachHubTokens.Dimens.spacingPage)
            }
            .dhScreen()
            .navigationDestination(isPresented: otpPresented) {
                OtpView(model: model)
            }
        }
    }

    /// Bước OTP hiện khi đã gửi mã; vuốt/bấm quay lại là đổi email.
    private var otpPresented: Binding<Bool> {
        Binding(
            get: { model.sentTo != nil },
            set: { if !$0 { model.changeEmail() } }
        )
    }

    private func send() {
        Task { await model.sendCode() }
    }
}

extension LoginModel.Failure {
    /// Câu báo tiếng Việt (Localizable.xcstrings) cho từng lỗi.
    var message: LocalizedStringKey {
        switch self {
        case .invalidEmail: "login.emailInvalid"
        case .otpInvalid: "otp.invalid"
        case .rateLimited: "login.rateLimited"
        case .offline: "error.offline"
        case .unavailable: "login.unavailable"
        case .generic: "login.failed"
        }
    }
}
