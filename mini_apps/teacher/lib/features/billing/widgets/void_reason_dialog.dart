import 'package:flutter/material.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../data/billing_models.dart';

/// Hộp thoại hủy có lý do bắt buộc (hủy hóa đơn, hủy thanh toán): trả lý do đã
/// cắt khoảng trắng, hoặc `null` khi giữ lại.
class VoidReasonDialog extends StatefulWidget {
  const VoidReasonDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
  });
  final String title;
  final String body;
  final String confirmLabel;

  @override
  State<VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<VoidReasonDialog> {
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
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _reason,
              label: l10n.billingVoidReason,
              maxLines: 3,
              errorText: _invalid ? l10n.billingErrReason : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.billingVoidKeep),
        ),
        TextButton(
          onPressed: () {
            final r = _reason.text.trim();
            if (r.isEmpty || r.length > voidReasonMax) {
              setState(() => _invalid = true);
              return;
            }
            Navigator.pop(context, r);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
