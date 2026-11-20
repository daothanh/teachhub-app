import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/l10n.dart';
import 'center_waitlist_cubit.dart';

/// [T01d] Đăng ký sớm Chủ trung tâm. Gửi xong quay về T01c để chọn Giáo viên.
class CenterWaitlistPage extends StatefulWidget {
  const CenterWaitlistPage({super.key});

  @override
  State<CenterWaitlistPage> createState() => _CenterWaitlistPageState();
}

class _CenterWaitlistPageState extends State<CenterWaitlistPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _count = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _count.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CenterWaitlistCubit>().submit(
      centerName: _name.text.trim(),
      teacherCount: int.parse(_count.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<CenterWaitlistCubit, CenterWaitlistState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status != WaitlistStatus.failure) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (state.error!.kind) {
              ApiErrorKind.conflict => l10n.waitlistErrorBusy,
              ApiErrorKind.validation => l10n.waitlistErrorValidation,
              ApiErrorKind.network => l10n.waitlistErrorNetwork,
              _ => l10n.waitlistErrorGeneric,
            }),
          ),
        );
      },
      builder: (context, state) {
        final busy = state.status == WaitlistStatus.submitting;
        final trial = AppButton(
          label: l10n.waitlistTrialAction,
          variant: AppButtonVariant.outlinePrimary,
          onPressed: () => context.go(AppRoutes.rolePicker),
        );
        return Scaffold(
          appBar: AppBar(title: Text(l10n.waitlistTitle)),
          body: state.status == WaitlistStatus.sent
              ? AppEmptyState(
                  message: l10n.waitlistSent,
                  subMessage: l10n.waitlistSentBody,
                  action: trial,
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(l10n.waitlistIntro),
                      const SizedBox(height: 16),
                      AppTextFormField(
                        controller: _name,
                        label: l10n.waitlistCenterName,
                        required: true,
                        maxLength: 120,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? l10n.waitlistCenterNameRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextFormField(
                        controller: _count,
                        label: l10n.waitlistTeacherCount,
                        required: true,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return n == null || n < 1 || n > 1000
                              ? l10n.waitlistTeacherCountInvalid
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppBanner(
                        tone: AppStatusTone.info,
                        description: l10n.waitlistTrialHint,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: l10n.waitlistSubmit,
                        onPressed: busy ? null : _submit,
                        disabled: busy,
                      ),
                      const SizedBox(height: 12),
                      trial,
                    ],
                  ),
                ),
        );
      },
    );
  }
}
