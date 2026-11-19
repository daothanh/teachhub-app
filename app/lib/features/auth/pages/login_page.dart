import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../core/network/api_error.dart';
import '../../../core/theme/teachhub_theme.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../l10n/l10n.dart';
import '../auth_config.dart';
import '../auth_cubit.dart';
import '../email_otp_sender.dart';
import '../sso/sso_cancelled.dart';
import '../widgets/login_hero.dart';
import '../widgets/otp_cells.dart';

/// [T01] Đăng nhập (Figma B01, B21, B31, B32) · [T01a] Nhập mã OTP (B02, B03,
/// B23, B24).
///
/// Chỉ email OTP, Google, Apple — không mật khẩu, không SMS (spec §1.4).
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.sendOtp,
    required this.google,
    required this.apple,
    this.isIOS,
  });

  final EmailOtpSender sendOtp;
  final SsoProvider google;
  final SsoProvider apple;

  /// Sign in with Apple native chỉ có trên iOS (bắt buộc ở đó, Guideline 4.8).
  final bool? isIOS;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Gửi lại OTP: 60 giây/lần (spec §5.2), không theo số mẫu trong mockup.
  static const _resendAfter = 60;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  bool _sending = false;
  bool _showEmailError = false;
  int _resendIn = 0;
  Timer? _resendTimer;

  /// T01a: lỗi mã (B23) và tạm khóa (B24).
  bool _codeInvalid = false;
  int? _attemptsLeft;
  int _lockedFor = 0;
  Timer? _lockTimer;

  bool get _emailValid =>
      _emailPattern.hasMatch(_email.text.trim().toLowerCase());

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _lockTimer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_emailValid) {
      setState(() => _showEmailError = true);
      return;
    }
    final email = _email.text.trim().toLowerCase();
    setState(() {
      _showEmailError = false;
      _sending = true;
    });
    try {
      await widget.sendOtp(email);
      if (!mounted) return;
      _code.clear();
      setState(() {
        _sentTo = email;
        _codeInvalid = false;
      });
      _resendTimer = _countdown(_resendAfter, (s) => _resendIn = s);
    } catch (e) {
      if (mounted) _showError(_errorMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Timer _countdown(int seconds, void Function(int) set) {
    setState(() => set(seconds));
    return Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => set(--seconds));
      if (seconds <= 0) t.cancel();
    });
  }

  void _verify() {
    final code = _code.text.trim();
    if (code.length != 6 || _lockedFor > 0) return;
    context.read<AppAuthCubit>().login(
      emailOtpCredentials(email: _sentTo!, code: code),
    );
  }

  void _changeEmail() {
    _lockTimer?.cancel();
    setState(() {
      _sentTo = null;
      _codeInvalid = false;
      _lockedFor = 0;
    });
  }

  void _onLoginFailed(Object? error) {
    final e = apiException(error);
    switch (e?.code) {
      case ApiErrorCode.otpInvalid:
        final left = e!.details['attemptsLeft'];
        setState(() {
          _codeInvalid = true;
          _attemptsLeft = left is int ? left : null;
        });
      case ApiErrorCode.otpLocked:
        _lockTimer?.cancel();
        _lockTimer = _countdown(e!.retryAfter?.inSeconds ?? 15 * 60, (s) {
          _lockedFor = s;
          if (s <= 0) _code.clear();
        });
      default:
        _showError(_errorMessage(context.l10n, error));
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  static String _errorMessage(AppLocalizations l10n, Object? error) =>
      switch (apiException(error)?.code) {
        ApiErrorCode.rateLimited => l10n.loginRateLimited,
        ApiErrorCode.serviceUnavailable => l10n.loginUnavailable,
        // Apple/Google không đủ thẩm quyền với email này: chỉ còn OTP email.
        ApiErrorCode.unauthenticated
            when apiException(error)?.details['reason'] ==
                'EMAIL_REQUIRES_OTP' =>
          l10n.loginEmailRequiresOtp,
        _ => l10n.loginFailed,
      };

  static String _mmss(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppAuthCubit, AppAuthState>(
      listenWhen: (a, b) =>
          (a.statusLogin != b.statusLogin &&
              b.statusLogin == LoadingStatus.failure) ||
          (a.statusSso != b.statusSso && b.statusSso == LoadingStatus.failure),
      listener: (context, state) {
        // Người dùng tự đóng hộp thoại Google/Apple: không phải lỗi.
        if (isSsoCancelled(state.error)) return;
        if (_sentTo != null) {
          _onLoginFailed(state.error);
        } else {
          _showError(_errorMessage(context.l10n, state.error));
        }
      },
      builder: (context, state) {
        final verifying = state.statusLogin == LoadingStatus.loading;
        final ssoBusy = state.statusSso == LoadingStatus.loading;
        return _sentTo == null
            ? _emailStep(context, busy: _sending || ssoBusy)
            : _otpStep(context, verifying: verifying);
      },
    );
  }

  // ── T01 ──────────────────────────────────────────────────────────────────

  Widget _emailStep(BuildContext context, {required bool busy}) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isIOS = widget.isIOS ?? Platform.isIOS;
    final auth = context.read<AppAuthCubit>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              tokens.spacingPage,
              tokens.spacingPage,
              tokens.spacingPage,
              tokens.spacingControl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    viewport.maxHeight -
                    tokens.spacingPage -
                    tokens.spacingControl,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const BrandMark(),
                        SizedBox(width: tokens.spacingContent),
                        Text(l10n.appName, style: text.headlineLarge),
                      ],
                    ),
                    SizedBox(height: tokens.spacingControl * 2),
                    Text(l10n.loginSlogan, style: text.headlineLarge),
                    SizedBox(height: tokens.spacingInline),
                    Text(
                      l10n.loginTagline,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.spacingContent),
                    const LoginHero(),
                    SizedBox(height: tokens.spacingContent),
                    const Spacer(),
                    if (isIOS) ...[
                      _SsoButton(
                        label: l10n.loginApple,
                        logo: const _AppleLogo(),
                        borderColor: scheme.onSurface,
                        onPressed: busy
                            ? null
                            : () => auth.loginWithSso(widget.apple),
                      ),
                      SizedBox(height: tokens.spacingContent),
                    ],
                    _SsoButton(
                      label: l10n.loginGoogle,
                      logo: Image.asset(
                        'assets/images/login/google_g.png',
                        width: 20,
                        height: 20,
                      ),
                      // Google branding (Light): viền #747775 — màu của Google, không phải token DS.
                      borderColor: const Color(0xFF747775),
                      onPressed: busy
                          ? null
                          : () => auth.loginWithSso(widget.google),
                    ),
                    SizedBox(height: tokens.spacingContent),
                    _labelledDivider(context, l10n.loginOrEmail),
                    SizedBox(height: tokens.spacingContent),
                    AppInput(
                      controller: _email,
                      label: l10n.loginEmail,
                      hint: l10n.loginEmailHint,
                      helperText: _showEmailError
                          ? null
                          : l10n.loginEmailHelper,
                      errorText: _showEmailError
                          ? l10n.loginEmailInvalid
                          : null,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.send,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _send(),
                      // B21: kit không tự đổi viền khi có lỗi.
                      borderColor: _showEmailError ? scheme.error : null,
                      focusedBorderColor: _showEmailError ? scheme.error : null,
                      errorBorderColor: scheme.onErrorContainer,
                    ),
                    SizedBox(height: tokens.spacingContent),
                    _primaryButton(
                      context,
                      label: l10n.loginSendOtp,
                      loadingLabel: l10n.loginSending,
                      loading: _sending,
                      onPressed: busy || !_emailValid ? null : _send,
                    ),
                    SizedBox(height: tokens.spacingContent),
                    _terms(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelledDivider(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    final line = Expanded(
      child: Divider(color: Theme.of(context).dividerColor),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.tasco.spacingContent,
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        line,
      ],
    );
  }

  Widget _terms(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final link = base?.copyWith(
      color: scheme.secondary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.secondary,
    );
    // shortcut: chưa có URL Điều khoản/Chính sách (S0-PO-13) nên chưa mở được;
    // gắn launchUrl vào `recognizer` khi PO chốt URL công khai.
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: l10n.loginTermsPrefix),
          TextSpan(text: l10n.loginTerms, style: link),
          TextSpan(text: l10n.loginTermsAnd),
          TextSpan(text: l10n.loginPrivacy, style: link),
          TextSpan(text: l10n.loginTermsSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Nút chính; khi [loading] giữ nền lime và hiện spinner + nhãn (B03, B32).
  Widget _primaryButton(
    BuildContext context, {
    required String label,
    required String loadingLabel,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // tasco_ui_kit chỉ tô màu disabled khi `disabled: true`; onPressed null chỉ chặn bấm.
    if (!loading) {
      return AppButton(
        label: label,
        onPressed: onPressed,
        disabled: onPressed == null,
      );
    }
    return AppButton(
      onPressed: null,
      disabled: true,
      disabledColor: scheme.primary,
      disabledForegroundColor: scheme.onPrimary,
      semanticLabel: loadingLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.onPrimary,
            ),
          ),
          SizedBox(width: context.tasco.spacingControl),
          Text(
            loadingLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }

  // ── T01a ─────────────────────────────────────────────────────────────────

  Widget _otpStep(BuildContext context, {required bool verifying}) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locked = _lockedFor > 0;

    final caption = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final Widget status;
    if (locked) {
      status = Text(l10n.otpRetryIn(_mmss(_lockedFor)), style: caption);
    } else if (_codeInvalid) {
      status = Text(
        _attemptsLeft == null
            ? l10n.otpInvalid
            : l10n.otpInvalidAttempts(_attemptsLeft!),
        style: text.bodySmall?.copyWith(color: scheme.onErrorContainer),
      );
    } else if (_resendIn > 0) {
      status = Text(l10n.otpResendIn(_mmss(_resendIn)), style: caption);
    } else {
      status = TextButton(
        onPressed: _sending ? null : _send,
        style: TextButton.styleFrom(textStyle: TeachHubTheme.buttonSmall),
        child: Text(l10n.loginResend),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        titleSpacing: 0,
        centerTitle:
            false, // B02: tiêu đề sát nút back (kit mặc định canh giữa)
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(TeachHubIcons.caretLeft),
          onPressed: verifying ? null : _changeEmail,
        ),
        title: Text(l10n.otpTitle),
        shape: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.spacingPage,
          tokens.spacingSection,
          tokens.spacingPage,
          tokens.spacingPage,
        ),
        children: [
          if (locked) ...[
            _lockedBanner(context),
            SizedBox(height: tokens.spacingPage),
          ],
          Text(l10n.otpHeading, style: text.headlineMedium),
          SizedBox(height: tokens.spacingInline),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.otpSentTo(_sentTo!),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: verifying ? null : _changeEmail,
                style: TextButton.styleFrom(
                  textStyle: TeachHubTheme.buttonSmall,
                  minimumSize: const Size(44, 44),
                ),
                child: Text(l10n.loginChangeEmail),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingInline),
          OtpCells(
            controller: _code,
            semanticLabel: l10n.otpCodeLabel,
            state: locked
                ? OtpCellsState.locked
                : _codeInvalid
                ? OtpCellsState.error
                : OtpCellsState.normal,
            onChanged: (v) {
              if (_codeInvalid) setState(() => _codeInvalid = false);
              if (v.length == 6) _verify();
            },
          ),
          SizedBox(height: tokens.spacingPage),
          Center(child: status),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: locked
            ? AppButton(label: l10n.otpLocked, onPressed: null, disabled: true)
            : _primaryButton(
                context,
                label: l10n.otpConfirm,
                loadingLabel: l10n.otpVerifying,
                loading: verifying,
                onPressed: _code.text.length == 6 ? _verify : null,
              ),
      ),
    );
  }

  /// `Feedback/Banner` Error — viền đứt (B24).
  Widget _lockedBanner(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DashedBorder(
      color: scheme.error,
      radius: tokens.cardRadius,
      child: Container(
        padding: EdgeInsets.all(tokens.spacingContent),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(TeachHubIcons.xCircle, size: 20, color: scheme.error),
            SizedBox(width: tokens.spacingContent),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.otpLockedTitle,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.otpLockedBody,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút "Tiếp tục với Google/Apple" theo quy định thương hiệu của hai hãng, không
/// theo kiểu nút Secondary của DS: nền trắng, chữ và logo Apple màu chữ chính
/// (#1F1F1F), logo Google giữ nguyên màu (Google Identity branding, Apple HIG
/// "Sign in with Apple").
class _SsoButton extends StatelessWidget {
  const _SsoButton({
    required this.label,
    required this.logo,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final Widget logo;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tasco;
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        textStyle: Theme.of(context).textTheme.labelLarge,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: logo),
          SizedBox(width: tokens.spacingControl),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Logo Apple của gói `sign_in_with_apple` (cùng logo nút chính thức vẽ), cùng màu chữ.
class _AppleLogo extends StatelessWidget {
  const _AppleLogo();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 17,
    height: 20,
    child: CustomPaint(
      painter: AppleLogoPainter(
        color:
            DefaultTextStyle.of(context).style.color ??
            Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}
