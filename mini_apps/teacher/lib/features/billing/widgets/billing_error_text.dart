import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../fees/widgets/fees_error_text.dart';

/// Thông điệp tiếng Việt cho lỗi kỳ thu và hóa đơn; còn lại dùng bảng lỗi chung
/// của học phí (`PAYOUT_ACCOUNT_MISSING`, 429, mạng…).
String billingErrorText(MiniAppLocalizations l10n, ApiException e) =>
    switch (e.code) {
      ApiErrorCode.invoiceImmutable => l10n.billingErrImmutable,
      ApiErrorCode.conflictStale => l10n.billingErrStale,
      _ => feesErrorText(l10n, e),
    };
