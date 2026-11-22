import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../cubit/receipt_claim_cubit.dart';

String claimErrorText(MiniAppLocalizations l10n, ClaimError e) => switch (e) {
  ClaimError.typeNotAllowed => l10n.invoiceClaimErrType,
  ClaimError.tooLarge => l10n.invoiceClaimErrLarge,
  ClaimError.amountInvalid => l10n.invoiceClaimErrAmount,
  ClaimError.noteTooLong => l10n.invoiceClaimErrNote,
  ClaimError.offline => l10n.invoiceClaimErrOffline,
  ClaimError.expired => l10n.invoiceClaimErrExpired,
  ClaimError.alreadyPending => l10n.invoiceClaimErrPending,
  ClaimError.notPayable => l10n.invoiceClaimErrNotPayable,
  ClaimError.notFound => l10n.invoiceClaimErrNotFound,
  ClaimError.rateLimited => l10n.invoiceClaimErrRate,
  ClaimError.failed => l10n.invoiceClaimErrFailed,
};

/// P03: sheet "Tôi đã chuyển khoản" (US-7.7 AC1): chọn ảnh biên lai, số tiền
/// (mặc định còn nợ), ghi chú. Đóng với `true` khi hóa đơn đã đổi (gửi xong,
/// hoặc 409/không còn báo được) để trang tải lại.
class ReceiptClaimSheet extends StatefulWidget {
  const ReceiptClaimSheet({super.key, required this.remaining});

  /// Số còn nợ lúc mở sheet: giá trị mặc định của ô số tiền.
  final int remaining;

  @override
  State<ReceiptClaimSheet> createState() => _ReceiptClaimSheetState();
}

class _ReceiptClaimSheetState extends State<ReceiptClaimSheet> {
  late final _amount = TextEditingController(text: '${widget.remaining}');
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    return BlocConsumer<ReceiptClaimCubit, ReceiptClaimState>(
      listenWhen: (a, b) => !a.invoiceChanged && b.invoiceChanged,
      listener: (context, s) => Navigator.pop(context, true),
      builder: (context, s) {
        final cubit = context.read<ReceiptClaimCubit>();
        final err = s.error;
        final retry =
            err == ClaimError.offline ||
            err == ClaimError.expired ||
            err == ClaimError.failed ||
            err == ClaimError.rateLimited;
        return PopScope(
          // Đang tải thì không đóng ngang: tránh bỏ dở giữa các bước.
          canPop: !s.busy,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.invoiceClaimTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.invoiceClaimHint, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  if (s.image != null)
                    Center(
                      child: Semantics(
                        label: l10n.invoiceClaimImageLabel,
                        image: true,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            s.image!.bytes,
                            height: 160,
                            // Giải mã nhỏ để xem trước không giữ ảnh cỡ đầy đủ.
                            cacheHeight: 320,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_not_supported, size: 48),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: s.busy ? null : cubit.pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      s.image == null
                          ? l10n.invoiceClaimPick
                          : l10n.invoiceClaimChange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: _amount,
                    label: l10n.invoiceClaimAmount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !s.busy,
                    errorText: err == ClaimError.amountInvalid
                        ? l10n.invoiceClaimErrAmount
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: _note,
                    label: l10n.invoiceClaimNote,
                    maxLines: 3,
                    maxLength: 300,
                    enabled: !s.busy,
                    errorText: err == ClaimError.noteTooLong
                        ? l10n.invoiceClaimErrNote
                        : null,
                  ),
                  if (s.busy) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(switch (s.stage!) {
                        ClaimStage.upload => l10n.invoiceClaimUploading(
                          (s.progress * 100).round(),
                        ),
                        ClaimStage.verify => l10n.invoiceClaimVerifying,
                        ClaimStage.claim => l10n.invoiceClaimSending,
                      }),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: s.stage == ClaimStage.upload ? s.progress : null,
                    ),
                  ],
                  // Lỗi ô nhập hiện ngay dưới ô; còn lại báo chung ở đây.
                  if (err != null &&
                      err != ClaimError.amountInvalid &&
                      err != ClaimError.noteTooLong) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        claimErrorText(l10n, err),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: retry
                        ? l10n.invoiceClaimRetry
                        : l10n.invoiceClaimSubmit,
                    width: double.infinity,
                    disabled: s.busy || s.image == null,
                    onPressed: () => cubit.submit(
                      amount: int.tryParse(_amount.text),
                      note: _note.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
