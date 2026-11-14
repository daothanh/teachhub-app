import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../l10n/l10n.dart';
import '../role_picker/membership_cubit.dart';
import 'invite_cubit.dart';

/// Nhận lời mời của giáo viên (link `teachhub.vn/i/<token>`).
class InvitePage extends StatelessWidget {
  const InvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<InviteCubit, InviteState>(
      listenWhen: (a, b) => a.statusAccept != b.statusAccept,
      listener: (context, state) {
        if (state.statusAccept != LoadingStatus.success) return;
        final active = context.read<MembershipCubit>().state.active;
        context.go(active?.role.rootRoute ?? TeachHubRoutes.rolePicker);
      },
      builder: (context, state) {
        final cubit = context.read<InviteCubit>();
        final busy = state.statusAccept == LoadingStatus.loading;
        final needsConsent = state.consentTermsVersion != null;
        final failed =
            state.statusAccept == LoadingStatus.failure && !needsConsent;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.inviteTitle)),
          body: AppEmptyState(
            message: needsConsent ? l10n.inviteConsentTitle : l10n.inviteTitle,
            subMessage: needsConsent
                ? l10n.inviteConsentBody
                : failed
                ? (state.errorCode == 'NOT_FOUND'
                      ? l10n.inviteInvalid
                      : l10n.inviteFailed)
                : l10n.inviteBody,
            action: AppButton(
              label: busy
                  ? l10n.loading
                  : needsConsent
                  ? l10n.inviteConsentAccept
                  : l10n.inviteAccept,
              onPressed: busy
                  ? null
                  : needsConsent
                  ? cubit.consentAndAccept
                  : cubit.accept,
            ),
          ),
        );
      },
    );
  }
}
