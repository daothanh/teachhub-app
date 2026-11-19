import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../classes/data/class_models.dart';
import '../../classes/widgets/classes_error_text.dart';
import '../cubit/invite_link_cubit.dart';
import '../data/invite_repository.dart';
import '../data/invite_sharer.dart';
import 'invite_link_card.dart';

/// "Chia sẻ link" / "Gửi lại link" của một phụ huynh (US-1.6 AC2, AC4): tạo
/// link rồi mở ngay bảng chia sẻ của hệ điều hành; tờ này giữ QR và mã ngắn để
/// đưa trực tiếp khi gặp mặt. Trả `true` nếu đã cấp link (danh sách cần tải lại).
Future<bool> showInviteShareSheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
  required RosterGuardian guardian,
  InviteRepository? repository,
}) async {
  final cubit = InviteLinkCubit(
    repository ?? inviteRepository(),
    studentId,
    guardian,
  );
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _InviteSheet(studentName: studentName, guardian: guardian),
    ),
  );
  final created = cubit.state.status == InviteLinkStatus.ready;
  await cubit.close();
  return created;
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.studentName, required this.guardian});
  final String studentName;
  final RosterGuardian guardian;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  String get studentName => widget.studentName;
  RosterGuardian get guardian => widget.guardian;

  @override
  void initState() {
    super.initState();
    // Bắt đầu sau khi listener bên dưới đã gắn, kẻo bỏ lỡ lần có link.
    unawaited(context.read<InviteLinkCubit>().start());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<InviteLinkCubit, InviteLinkState>(
      // Vừa có link thì mở luôn bảng chia sẻ, đúng US-1.6 AC2.
      listenWhen: (a, b) =>
          a.status != InviteLinkStatus.ready &&
          b.status == InviteLinkStatus.ready,
      listener: (context, s) => inviteSharer().share(
        inviteMessage(
          l10n,
          guardianName: guardian.fullName,
          studentName: studentName,
          link: s.link!,
        ),
      ),
      builder: (context, s) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: switch (s.status) {
          InviteLinkStatus.loading => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          InviteLinkStatus.failure => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(classesErrorText(l10n, s.error!)),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.classesRetry,
                onPressed: context.read<InviteLinkCubit>().start,
              ),
            ],
          ),
          InviteLinkStatus.ready => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InviteLinkCard(
                link: s.link!,
                studentName: studentName,
                guardianName: guardian.fullName,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.inviteOldLinkNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        },
      ),
    );
  }
}
