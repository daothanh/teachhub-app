import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';

import '../../../core/network/api_error.dart';
import '../../../l10n/l10n.dart';
import '../auth_config.dart';
import '../auth_cubit.dart';
import '../email_otp_sender.dart';
import '../sso/sso_cancelled.dart';

/// [T01] Đăng nhập · [T01a] Nhập mã OTP.
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
  static const _resendAfter = Duration(seconds: 60);
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  bool _sending = false;
  String? _emailError;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final email = _email.text.trim().toLowerCase();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _emailError = l10n.loginEmailInvalid);
      return;
    }
    setState(() {
      _emailError = null;
      _sending = true;
    });
    try {
      await widget.sendOtp(email);
      if (!mounted) return;
      _code.clear();
      setState(() => _sentTo = email);
      _startCooldown();
    } catch (e) {
      if (mounted) _showError(_errorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendIn = _resendAfter.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  void _verify() {
    final code = _code.text.trim();
    if (code.length != 6) return;
    context.read<AppAuthCubit>().login(
      emailOtpCredentials(email: _sentTo!, code: code),
    );
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  static String _errorMessage(AppLocalizations l10n, Object? error) =>
      switch (apiErrorCode(error)) {
        'OTP_INVALID' => l10n.loginOtpInvalid,
        'RATE_LIMITED' => l10n.loginRateLimited,
        _ => l10n.loginFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final text = Theme.of(context).textTheme;
    final isIOS = widget.isIOS ?? Platform.isIOS;

    return BlocConsumer<AppAuthCubit, AppAuthState>(
      listenWhen: (a, b) =>
          (a.statusLogin != b.statusLogin &&
              b.statusLogin == LoadingStatus.failure) ||
          (a.statusSso != b.statusSso && b.statusSso == LoadingStatus.failure),
      listener: (context, state) {
        // Người dùng tự đóng hộp thoại Google/Apple: không phải lỗi.
        if (!isSsoCancelled(state.error)) {
          _showError(_errorMessage(l10n, state.error));
        }
      },
      builder: (context, state) {
        final busy =
            _sending ||
            state.statusLogin == LoadingStatus.loading ||
            state.statusSso == LoadingStatus.loading;
        final sentTo = _sentTo;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(tokens.spacingPage),
              children: [
                SizedBox(height: tokens.spacingPageLarge),
                Text(
                  l10n.appName,
                  style: text.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spacingInline),
                Text(
                  sentTo == null
                      ? l10n.loginSubtitle
                      : l10n.loginOtpSentTo(sentTo),
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spacingSection),
                if (sentTo == null) ...[
                  AppInput(
                    controller: _email,
                    label: l10n.loginEmail,
                    hint: l10n.loginEmailHint,
                    errorText: _emailError,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _send(),
                  ),
                  SizedBox(height: tokens.spacingContent),
                  AppButton(
                    label: busy ? l10n.loading : l10n.loginSendOtp,
                    onPressed: busy ? null : _send,
                  ),
                  SizedBox(height: tokens.spacingSection),
                  Text(
                    l10n.loginOr,
                    style: text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingContent),
                  AppButton(
                    label: l10n.loginGoogle,
                    variant: AppButtonVariant.outlinePrimary,
                    onPressed: busy
                        ? null
                        : () => context.read<AppAuthCubit>().loginWithSso(
                            widget.google,
                          ),
                  ),
                  if (isIOS) ...[
                    SizedBox(height: tokens.spacingControl),
                    AppButton(
                      label: l10n.loginApple,
                      variant: AppButtonVariant.outlinePrimary,
                      onPressed: busy
                          ? null
                          : () => context.read<AppAuthCubit>().loginWithSso(
                              widget.apple,
                            ),
                    ),
                  ],
                ] else ...[
                  AppInput(
                    controller: _code,
                    label: l10n.loginOtpCode,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    onChanged: (v) {
                      if (v.trim().length == 6) _verify();
                    },
                  ),
                  SizedBox(height: tokens.spacingContent),
                  AppButton(
                    label: busy ? l10n.loading : l10n.login,
                    onPressed: busy ? null : _verify,
                  ),
                  SizedBox(height: tokens.spacingControl),
                  AppButton(
                    label: _resendIn > 0
                        ? l10n.loginResendIn(_resendIn)
                        : l10n.loginResend,
                    variant: AppButtonVariant.grey,
                    onPressed: busy || _resendIn > 0 ? null : _send,
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _sentTo = null),
                    child: Text(l10n.loginChangeEmail),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
