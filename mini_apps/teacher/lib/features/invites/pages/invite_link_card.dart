import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../data/invite_models.dart';
import '../data/invite_sharer.dart';

/// Tin nhắn soạn sẵn gửi cho phụ huynh: link riêng và mã ngắn (US-1.6 AC2).
String inviteMessage(
  MiniAppLocalizations l10n, {
  required String guardianName,
  required String studentName,
  required InviteLink link,
}) => l10n.inviteShareMessage(
  guardianName,
  studentName,
  link.url,
  link.shortCode,
);

/// QR, mã ngắn và nút chia sẻ của một lời mời. Server chỉ trả link và mã ở
/// lần tạo, nên đây là chỗ duy nhất giáo viên xem được chúng.
class InviteLinkCard extends StatelessWidget {
  const InviteLinkCard({
    super.key,
    required this.link,
    required this.studentName,
    required this.guardianName,
    this.onShared,
  });

  final InviteLink link;
  final String studentName;
  final String guardianName;

  /// Gọi sau khi bảng chia sẻ của hệ điều hành đã đóng.
  final VoidCallback? onShared;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final spaced = link.shortCode.split('').join(' ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.inviteSheetFor(guardianName, studentName),
          style: text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Semantics(
            image: true,
            label: l10n.inviteQrLabel,
            child: ExcludeSemantics(
              // Nền trắng cố định: QR trên nền tối không quét được.
              child: QrImageView(
                data: link.url,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.inviteCodeLabel, style: text.bodySmall),
        Semantics(
          label: l10n.inviteCodeSemantics(spaced),
          excludeSemantics: true,
          child: SelectableText(
            link.shortCode,
            style: text.headlineSmall?.copyWith(letterSpacing: 4),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.inviteExpiryNote, style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Builder(
          builder: (context) => AppButton(
            label: l10n.inviteShare,
            width: double.infinity,
            onPressed: () async {
              final opened = await inviteSharer().share(
                inviteMessage(
                  l10n,
                  guardianName: guardianName,
                  studentName: studentName,
                  link: link,
                ),
                origin: shareOrigin(context),
              );
              if (opened) onShared?.call();
            },
          ),
        ),
      ],
    );
  }
}
