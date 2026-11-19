import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/l10n.dart';
import 'invite_entry_cubit.dart';
import 'invite_input.dart';
import 'invite_link_requester.dart';

/// P05: phụ huynh chưa có lời mời — giải thích và 3 cách kết nối (US-0.12
/// AC1): quét QR (P05b), dán link hoặc nhập mã, nhắn giáo viên xin link.
///
/// [onLinked] chạy khi nhận lời mời bằng mã thành công. Link/QR đi qua màn
/// thẻ lời mời ([AppRoutes.invite]) và tự về `/p` khi xong.
class InviteEntryView extends StatefulWidget {
  const InviteEntryView({
    super.key,
    required this.onLinked,
    this.requester = const InviteLinkRequester(),
    this.now = DateTime.now,
  });

  final VoidCallback onLinked;
  final InviteLinkRequester requester;

  /// Đồng hồ cho thông báo "còn N phút" (test thay được).
  final DateTime Function() now;

  @override
  State<InviteEntryView> createState() => _InviteEntryViewState();
}

class _InviteEntryViewState extends State<InviteEntryView> {
  final _text = TextEditingController();
  bool _badInput = false;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    // Đang khóa hoặc đang gửi: không làm gì, giữ nguyên nội dung đã nhập.
    final phase = context.read<InviteEntryCubit>().state.phase;
    if (phase == InviteEntryPhase.locked ||
        phase == InviteEntryPhase.submitting) {
      return;
    }
    final input = InviteInput.parse(raw);
    setState(() => _badInput = input == null);
    switch (input) {
      case null:
        return;
      case InviteToken(:final value):
        _text.clear();
        if (mounted) await context.push(AppRoutes.inviteCard, extra: value);
      case InviteCode(:final value):
        _text.clear();
        await context.read<InviteEntryCubit>().redeem(value);
    }
  }

  Future<void> _scan() async {
    final raw = await context.push<String>(AppRoutes.inviteScan);
    if (raw != null && mounted) await _submit(raw);
  }

  Future<void> _askTeacher() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await widget.requester.request(l10n.inviteAskMessage);
    if (outcome == InviteLinkRequestOutcome.zaloOpened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.inviteAskCopied)));
    }
  }

  Future<void> _onState(BuildContext context, InviteEntryState state) async {
    final cubit = context.read<InviteEntryCubit>();
    _tick?.cancel();
    // Cập nhật "còn N phút" theo thời gian khi đang khóa.
    _tick = state.phase == InviteEntryPhase.locked
        ? Timer.periodic(const Duration(seconds: 20), (_) {
            if (mounted) setState(() {});
          })
        : null;
    switch (state.phase) {
      case InviteEntryPhase.accepted:
        widget.onLinked();
      case InviteEntryPhase.consentRequired:
        final agreed = await context.push<bool>(AppRoutes.consent);
        // Bị đẩy sang màn khác trong lúc chờ (vd. điều khoản đổi giữa phiên ở
        // /p): view và cubit đã đóng, bỏ mã thay vì gọi lại.
        if (!mounted) return;
        if (agreed == true) {
          await cubit.redeem();
        } else {
          cubit.consentDeclined();
        }
      case _:
    }
  }

  String? _message(BuildContext context, InviteEntryState state) {
    final l10n = context.l10n;
    if (_badInput) return l10n.inviteInputBad;
    return switch (state.phase) {
      InviteEntryPhase.invalid => l10n.inviteCodeInvalid,
      InviteEntryPhase.locked => l10n.inviteCodeLocked(
        _minutesLeft(state.lockedUntil),
      ),
      InviteEntryPhase.failed =>
        state.errorCode == ApiErrorCode.rateLimited
            ? l10n.inviteRateLimited
            : l10n.inviteFailed,
      _ => null,
    };
  }

  int _minutesLeft(DateTime? until) {
    if (until == null) return 1;
    final left = until.difference(widget.now()).inSeconds;
    return left <= 0 ? 1 : (left / 60).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocConsumer<InviteEntryCubit, InviteEntryState>(
      listenWhen: (a, b) => a.phase != b.phase,
      listener: _onState,
      builder: (context, state) {
        final locked = state.phase == InviteEntryPhase.locked;
        final busy =
            state.phase == InviteEntryPhase.submitting ||
            state.phase == InviteEntryPhase.accepted;
        final message = _message(context, state);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.inviteEntryTitle,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.inviteEntryBody),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy || locked ? null : _scan,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.inviteScanQr),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              enabled: !locked && !busy,
              autocorrect: false,
              enableSuggestions: false,
              // Link/mã mời là bí mật: bàn phím không học, không gợi ý.
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inviteInputLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_badInput) setState(() => _badInput = false);
              },
              onSubmitted: (v) => _submit(v),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: locked || busy ? null : () => _submit(_text.text),
              child: Text(l10n.inviteInputSubmit),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _askTeacher,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.inviteAskTeacher),
            ),
          ],
        );
      },
    );
  }
}

/// P05 gắn vào P02 của mini-app parent khi chưa có con nào.
Widget embeddedInviteEntry(VoidCallback onLinked) => BlocProvider(
  create: (_) => GetIt.I<InviteEntryCubit>(),
  child: InviteEntryView(onLinked: onLinked),
);

/// P05 dạng màn riêng (`/invite`): thêm lời mời của giáo viên khác (US-0.4 AC1).
class InviteEntryPage extends StatelessWidget {
  const InviteEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.inviteTitle)),
      body: embeddedInviteEntry(() {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(TeachHubRoutes.parent);
        }
      }),
    );
  }
}
