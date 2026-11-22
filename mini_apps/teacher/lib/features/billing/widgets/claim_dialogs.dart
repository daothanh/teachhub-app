import 'package:flutter/material.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart'
    show VndInputFormatter, formatVnd, parseVnd;
import '../data/billing_models.dart' show paymentAmountMax;
import '../data/claim_models.dart';

/// Xác nhận một lần báo: sửa được số thực nhận (mặc định số phụ huynh khai).
/// Trả số tiền (VND), hoặc `null` khi đóng.
class ClaimConfirmDialog extends StatefulWidget {
  const ClaimConfirmDialog({super.key, required this.claim});
  final PaymentClaim claim;

  @override
  State<ClaimConfirmDialog> createState() => _ClaimConfirmDialogState();
}

class _ClaimConfirmDialogState extends State<ClaimConfirmDialog> {
  late final _amount = TextEditingController(
    text: formatVnd(widget.claim.amount),
  );
  bool _invalid = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return AlertDialog(
      title: Text(l10n.claimConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.claimConfirmHint(formatVnd(widget.claim.amount))),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _amount,
              label: l10n.claimConfirmAmount,
              keyboardType: TextInputType.number,
              inputFormatters: const [VndInputFormatter()],
              errorText: _invalid ? l10n.billingErrAmount : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.claimCancel),
        ),
        TextButton(
          onPressed: () {
            final v = parseVnd(_amount.text);
            if (v == null || v < 1 || v > paymentAmountMax) {
              setState(() => _invalid = true);
              return;
            }
            Navigator.pop(context, v);
          },
          child: Text(l10n.claimConfirm),
        ),
      ],
    );
  }
}

/// Từ chối một lần báo: lý do bắt buộc, gửi kèm thông báo cho phụ huynh.
/// Trả lý do đã cắt khoảng trắng, hoặc `null` khi đóng.
class ClaimRejectDialog extends StatefulWidget {
  const ClaimRejectDialog({super.key});

  @override
  State<ClaimRejectDialog> createState() => _ClaimRejectDialogState();
}

class _ClaimRejectDialogState extends State<ClaimRejectDialog> {
  final _reason = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return AlertDialog(
      title: Text(l10n.claimRejectTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.claimRejectHint),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _reason,
              label: l10n.claimRejectReason,
              maxLines: 3,
              maxLength: claimRejectReasonMax,
              errorText: _invalid ? l10n.billingErrReason : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.claimCancel),
        ),
        TextButton(
          onPressed: () {
            final r = _reason.text.trim();
            if (r.isEmpty || r.length > claimRejectReasonMax) {
              setState(() => _invalid = true);
              return;
            }
            Navigator.pop(context, r);
          },
          child: Text(l10n.claimReject),
        ),
      ],
    );
  }
}
