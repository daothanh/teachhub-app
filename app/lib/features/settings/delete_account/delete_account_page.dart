import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../core/routing/app_routes.dart';
import '../../../l10n/l10n.dart';
import '../../auth/logout_service.dart';
import '../../auth/widgets/otp_cells.dart';
import 'account_repository.dart';
import 'delete_account_cubit.dart';

/// Dựng cubit từ DI của shell; test truyền [cubit] giả.
class DeleteAccountScope extends StatelessWidget {
  const DeleteAccountScope({super.key, required this.email, this.cubit});
  final String email;
  final DeleteAccountCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? _fromDi())..load(),
      child: DeleteAccountPage(email: email),
    );
  }

  static DeleteAccountCubit _fromDi() {
    final logout = GetIt.I<LogoutService>();
    return DeleteAccountCubit(
      repository: GetIt.I<AccountRepository>(),
      pendingCount: logout.pendingCount,
      // Cảnh báo outbox đã hiện trước khi gửi mã nên bỏ qua hỏi lại.
      markDeleting: logout.markWipePending,
      clearDeleting: logout.clearWipePending,
      finish: () => logout.logout(confirmDiscard: (_) async => true),
    );
  }
}

/// Xóa tài khoản: cảnh báo, rồi nhập OTP gửi tới email, rồi xóa (S4-FL-04).
/// Xong thì về T01 (đăng nhập) vì phiên đã bị xóa.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, required this.email});
  final String email;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _failureText(DeleteAccountState s) {
    final l10n = context.l10n;
    return switch (s.failure!) {
      DeleteFailure.network => l10n.deleteAccountErrNetwork,
      DeleteFailure.otpInvalid =>
        s.attemptsLeft == null
            ? l10n.otpInvalid
            : l10n.otpInvalidAttempts(s.attemptsLeft!),
      DeleteFailure.otpLocked => l10n.otpLockedBody,
      DeleteFailure.rateLimited =>
        s.retryAfterSec == null
            ? l10n.deleteAccountErrRateLimitedNoTime
            : l10n.deleteAccountErrRateLimited(s.retryAfterSec!),
      DeleteFailure.ownerHasStaff => l10n.deleteAccountErrOwnerHasStaff,
      DeleteFailure.tenantHasActiveClasses =>
        l10n.deleteAccountErrActiveClasses,
      DeleteFailure.stale => l10n.deleteAccountErrStale,
      DeleteFailure.generic => l10n.deleteAccountErrGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listenWhen: (a, b) => a.step != b.step || a.failure != b.failure,
      listener: (context, s) {
        if (s.step == DeleteStep.done) context.go(AppRoutes.login);
        if (s.failure == DeleteFailure.otpInvalid ||
            s.failure == DeleteFailure.otpLocked) {
          _code.clear();
        }
      },
      builder: (context, s) {
        final cubit = context.read<DeleteAccountCubit>();
        final inCode = s.step != DeleteStep.confirm;
        final locked = s.failure == DeleteFailure.otpLocked;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.deleteAccountWarnHeading,
                style: text.titleLarge?.copyWith(color: scheme.error),
              ),
              const SizedBox(height: 12),
              Text(l10n.deleteAccountWarnBody(widget.email)),
              if (s.pendingLoaded && s.pending != 0) ...[
                const SizedBox(height: 12),
                Semantics(
                  container: true,
                  child: Text(
                    s.pending == null
                        ? l10n.deleteAccountUnreadableWarn
                        : l10n.deleteAccountPendingWarn(s.pending!),
                    style: text.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ),
              ],
              if (inCode) ...[
                const SizedBox(height: 24),
                Text(l10n.deleteAccountCodeHeading, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(l10n.deleteAccountCodeSent(widget.email)),
                const SizedBox(height: 12),
                OtpCells(
                  controller: _code,
                  semanticLabel: l10n.otpCodeLabel,
                  state: locked
                      ? OtpCellsState.locked
                      : s.failure == DeleteFailure.otpInvalid
                      ? OtpCellsState.error
                      : OtpCellsState.normal,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (s.failure != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _failureText(s),
                      style: text.bodyMedium?.copyWith(color: scheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (!inCode)
                AppButton(
                  label: s.busy
                      ? l10n.deleteAccountSending
                      : l10n.deleteAccountSendCode,
                  disabled: s.busy,
                  variant: AppButtonVariant.outlineDanger,
                  onPressed: s.busy ? null : () => cubit.sendCode(widget.email),
                )
              else ...[
                AppButton(
                  label: s.busy
                      ? l10n.deleteAccountDeleting
                      : l10n.deleteAccountConfirm,
                  variant: AppButtonVariant.outlineDanger,
                  disabled: s.busy || locked || _code.text.length != 6,
                  onPressed: s.busy || locked || _code.text.length != 6
                      ? null
                      : () => cubit.confirm(_code.text),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: s.busy ? null : () => cubit.sendCode(widget.email),
                  child: Text(l10n.deleteAccountResend),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
