import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';

/// Thông điệp tiếng Việt theo mã lỗi (spec §5.6); `message` của server không hiển thị.
/// [enroll] đổi lời 409 cho thao tác ghi danh.
String classesErrorText(
  MiniAppLocalizations l10n,
  ApiException e, {
  bool enroll = false,
}) {
  switch (e.code) {
    case ApiErrorCode.planLimitExceeded:
      return l10n.classesErrPlanLimit;
    case ApiErrorCode.idempotencyInProgress:
      return l10n.classesErrBusy;
    case ApiErrorCode.conflictStale:
      return enroll ? l10n.classesErrEnrollConflict : l10n.classesErrStale;
    default:
  }
  return switch (e.kind) {
    ApiErrorKind.network => l10n.classesErrNetwork,
    ApiErrorKind.paymentRequired => l10n.classesErrPlanLimit,
    ApiErrorKind.forbidden => l10n.classesErrForbidden,
    ApiErrorKind.notFound => l10n.classesErrNotFound,
    ApiErrorKind.conflict => l10n.classesErrStale,
    ApiErrorKind.validation => l10n.classesErrValidation,
    _ => l10n.classesErrGeneric,
  };
}
