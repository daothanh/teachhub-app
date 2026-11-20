import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/l10n.dart';
import 'invite_cubit.dart';
import 'invite_link_requester.dart';

/// Thẻ lời mời (tên giáo viên, tên con) rồi nhận lời mời (US-0.3, US-0.12 AC2).
/// Chưa đồng ý điều khoản thì mở màn đồng ý trước khi nhận.
class InvitePage extends StatefulWidget {
  const InvitePage({super.key, this.requester = const InviteLinkRequester()});

  final InviteLinkRequester requester;

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  @override
  void initState() {
    super.initState();
    context.read<InviteCubit>().load();
  }

  Future<void> _onState(BuildContext context, InviteState state) async {
    final cubit = context.read<InviteCubit>();
    switch (state.phase) {
      case InvitePhase.accepted:
        context.go(TeachHubRoutes.parent);
      case InvitePhase.consentRequired:
        final agreed = await context.push<bool>(AppRoutes.consent);
        if (!mounted) return;
        if (agreed == true) {
          await cubit.accept();
        } else {
          cubit.consentDeclined();
        }
      case _:
    }
  }

  Future<void> _askTeacher() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await widget.requester.request(l10n.inviteAskMessage);
    if (outcome == InviteLinkRequestOutcome.zaloOpened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.inviteAskCopied)));
    }
  }

  String _date(DateTime d) => DateFormat.yMd(
    Localizations.localeOf(context).toString(),
  ).format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocConsumer<InviteCubit, InviteState>(
      listenWhen: (a, b) => a.phase != b.phase,
      listener: _onState,
      builder: (context, state) {
        final cubit = context.read<InviteCubit>();
        final preview = state.preview;
        final busy =
            state.phase == InvitePhase.accepting ||
            state.phase == InvitePhase.accepted ||
            state.phase == InvitePhase.consentRequired;
        final children = <Widget>[];
        switch (state.phase) {
          case InvitePhase.loading:
            children.add(const Center(child: CircularProgressIndicator()));
          case InvitePhase.invalid:
            children
              ..add(
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.inviteInvalid,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
              ..add(const SizedBox(height: 16))
              ..add(
                FilledButton.icon(
                  onPressed: _askTeacher,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.inviteAskTeacher),
                ),
              );
          case InvitePhase.failed when preview == null:
            children
              ..add(
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.errorCode == ApiErrorCode.rateLimited
                        ? l10n.inviteRateLimited
                        : l10n.inviteFailed,
                  ),
                ),
              )
              ..add(const SizedBox(height: 16))
              ..add(
                FilledButton(onPressed: cubit.load, child: Text(l10n.retry)),
              );
          case _:
            if (preview != null) {
              children
                ..add(
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.inviteCardTitle(preview.teacherName),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                )
                ..add(const SizedBox(height: 8))
                ..add(
                  Text(
                    l10n.inviteCardBody(
                      preview.teacherName,
                      preview.studentGivenName,
                      _date(preview.expiresAt),
                    ),
                  ),
                );
              if (state.phase == InvitePhase.failed) {
                children
                  ..add(const SizedBox(height: 8))
                  ..add(
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        state.errorCode == ApiErrorCode.rateLimited
                            ? l10n.inviteRateLimited
                            : l10n.inviteFailed,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
              }
              children
                ..add(const SizedBox(height: 24))
                ..add(
                  FilledButton(
                    onPressed: busy ? null : cubit.accept,
                    child: Text(busy ? l10n.loading : l10n.inviteAccept),
                  ),
                );
            }
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.inviteTitle)),
          body: ListView(padding: const EdgeInsets.all(16), children: children),
        );
      },
    );
  }
}
