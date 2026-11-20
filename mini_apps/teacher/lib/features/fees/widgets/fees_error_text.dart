import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../classes/widgets/classes_error_text.dart';

/// Thông điệp tiếng Việt cho lỗi học phí và tài khoản nhận tiền. 429 (kể cả
/// `OTP_LOCKED`) không kèm đếm ngược, không thử lại tự động.
String feesErrorText(MiniAppLocalizations l10n, ApiException e) =>
    switch (e.code) {
      ApiErrorCode.otpInvalid => l10n.payoutErrOtpInvalid,
      ApiErrorCode.otpLocked => l10n.payoutErrOtpLocked,
      ApiErrorCode.rateLimited => l10n.feesErrRateLimited,
      ApiErrorCode.payoutAccountMissing => l10n.payoutErrMissing,
      _ => classesErrorText(l10n, e),
    };
