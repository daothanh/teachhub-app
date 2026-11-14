import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart' show ApiErrorType, ApiException;
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';

import '../../../l10n/l10n.dart';
import '../auth_cubit.dart';
import '../forms/login_form.dart';

/// Localized copy for a failed sign-in.
///
/// Never the error itself: `toString()` of a `DioException` or `StateError` is
/// developer text in no particular language, and can carry request details.
/// Only [ApiException.type] is read — its `message` is not localized either.
/// Connectivity gets its own copy because "check your credentials" would send
/// the user after the wrong problem.
String _loginFailureMessage(AppLocalizations l10n, Object? error) {
  final type = error is DioException
      ? ApiException.fromDioException(error).type
      : null;
  return switch (type) {
    ApiErrorType.noConnection || ApiErrorType.timeout => l10n.loginNetworkError,
    _ => l10n.loginFailed,
  };
}

/// Builds the sign-in request body from what the user typed.
///
/// The router supplies it, so the page knows neither the backend's body shape
/// nor where the client id and device identity come from.
typedef LoginCredentials =
    Map<String, dynamic> Function({
      required String username,
      required String password,
    });

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.credentials});

  final LoginCredentials credentials;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Holds both fields' text; no controller per field (ADR-0036).
  final _form = AppFormController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.validate()) return;
    final (:username, :password) = loginCredentialsFromForm(_form.values);
    context.read<AppAuthCubit>().login(
      widget.credentials(username: username, password: password),
    );
  }

  void _loginWithSso(String providerId, String providerName) {
    final provider = GenericSsoProvider(
      providerId: providerId,
      onAuthenticate: () async => SsoResult(
        idToken: 'mock_id_token_$providerId',
        accessToken: 'mock_access_token_$providerId',
        extra: {'email': 'user@$providerId.com', 'name': '$providerName User'},
      ),
    );
    context.read<AppAuthCubit>().loginWithSso(provider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<AppAuthCubit, AppAuthState>(
      listener: (context, state) {
        if (state.statusLogin == LoadingStatus.failure ||
            state.statusSso == LoadingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_loginFailureMessage(l10n, state.error)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting =
            state.statusLogin == LoadingStatus.loading ||
            state.statusSso == LoadingStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.backgroundMyTasco,
          appBar: AppMainAppBar(
            title: l10n.login,
            showLeading: Navigator.of(context).canPop(),
            onLeadingTap: () => Navigator.of(context).pop(),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: AppForm(
                  controller: _form,
                  // One flag for every field; the buttons below read
                  // isSubmitting themselves.
                  enabled: !isSubmitting,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Brand Logo
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AppSvgIcon(
                            AppIcons.logo,
                            color: Colors.white,
                            width: 140.w,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        l10n.loginWelcomeTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        l10n.loginWelcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Input Fields. The form shows no error until the first
                      // submit, then each field updates its own as it is
                      // edited, without announcing on every keystroke. The
                      // autofill group lets a password manager fill and save
                      // the pair.
                      AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextFormField(
                              name: LoginFormFields.username,
                              label: l10n.username,
                              hint: l10n.username,
                              prefix: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: AppSvgIcon(
                                  AppIcons.user,
                                  size: 20.sp,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              // The username is sent trimmed; the password is not.
                              toValueTransformer: (value) => value?.trim(),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              validator: (value) => AppValidators.required(
                                value,
                                message: l10n.loginUsernameRequired,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            AppTextFormField(
                              name: LoginFormFields.password,
                              label: l10n.password,
                              hint: l10n.password,
                              obscureText: _obscurePassword,
                              prefix: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: AppSvgIcon(
                                  AppIcons.lock,
                                  size: 20.sp,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              suffix: IconButton(
                                icon: AppSvgIcon(
                                  _obscurePassword
                                      ? AppIcons.eyeSlash
                                      : AppIcons.eye,
                                  size: 20.sp,
                                  color: scheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _submit(),
                              validator: (value) => AppValidators.required(
                                value,
                                message: l10n.loginPasswordRequired,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Submit Primary Button
                      AppButton(
                        label: isSubmitting ? l10n.loading : l10n.login,
                        variant: AppButtonVariant.primary,
                        disabled: isSubmitting,
                        onPressed: isSubmitting ? null : _submit,
                      ),

                      // Biometric Login Option (if enabled & available)
                      if (state.isBiometricAvailable &&
                          state.isBiometricEnabled) ...[
                        SizedBox(height: 12.h),
                        AppButton(
                          label: l10n.settingsBiometricTitle,
                          variant: AppButtonVariant.outlinePrimary,
                          icon: AppSvgIcon(
                            AppIcons.fingerprint,
                            size: 20.sp,
                            color: scheme.primary,
                          ),
                          disabled: isSubmitting,
                          onPressed: isSubmitting
                              ? null
                              : () => context
                                    .read<AppAuthCubit>()
                                    .authenticateWithBiometrics(
                                      localizedReason:
                                          l10n.settingsBiometricAuthReason,
                                    ),
                        ),
                      ],

                      // SSO Social / Enterprise Login Divider
                      SizedBox(height: 28.h),
                      Row(
                        children: [
                          const Expanded(child: AppDivider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              l10n.loginSsoOr,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: AppDivider()),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // SSO Buttons
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: l10n.loginGoogle,
                              variant: AppButtonVariant.grey,
                              icon: AppSvgIcon(AppIcons.gmail, size: 18.sp),
                              disabled: isSubmitting,
                              onPressed: isSubmitting
                                  ? null
                                  : () => _loginWithSso('google', 'Google'),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: AppButton(
                              label: l10n.loginApple,
                              variant: AppButtonVariant.grey,
                              icon: AppSvgIcon(
                                AppIcons.security,
                                size: 18.sp,
                                color: scheme.onSurface,
                              ),
                              disabled: isSubmitting,
                              onPressed: isSubmitting
                                  ? null
                                  : () => _loginWithSso('apple', 'Apple'),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: AppButton(
                              label: l10n.loginCorporateSso,
                              variant: AppButtonVariant.grey,
                              icon: AppSvgIcon(
                                AppIcons.buildingShield,
                                size: 18.sp,
                                color: scheme.onSurface,
                              ),
                              disabled: isSubmitting,
                              onPressed: isSubmitting
                                  ? null
                                  : () =>
                                        _loginWithSso('corporate', 'Tasco SSO'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
