import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../fees/widgets/fees_error_text.dart';

/// Thông điệp tiếng Việt cho lỗi kỳ thu và hóa đơn; còn lại dùng bảng lỗi chung
/// của học phí (`PAYOUT_ACCOUNT_MISSING`, 429, mạng…).
///
/// [staleUnverified]: 409 `CONFLICT_STALE` nhưng tải lại cũng lỗi, nên không
/// được nói là đã cập nhật.
String billingErrorText(
  MiniAppLocalizations l10n,
  ApiException e, {
  bool staleUnverified = false,
}) => switch (e.code) {
  ApiErrorCode.invoiceImmutable => l10n.billingErrImmutable,
  ApiErrorCode.invoiceNotPayable => l10n.billingErrNotPayable,
  ApiErrorCode.conflictStale =>
    staleUnverified ? l10n.billingErrStaleUnverified : l10n.billingErrStale,
  _ => feesErrorText(l10n, e),
};
