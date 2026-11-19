import 'package:dio/dio.dart';

import 'api_error_code.dart';

export 'api_error_code.dart';

/// Nhóm lỗi để client xử lý thống nhất (bảng "Client xử lý" ở spec §5.6).
enum ApiErrorKind {
  /// Mất mạng, timeout — không có phản hồi từ API.
  network,

  /// 400 — lỗi chung.
  badRequest,

  /// 401 — tự làm mới token 1 lần; lỗi tiếp → về màn đăng nhập.
  unauthenticated,

  /// 402 — vượt gói / tính năng Pro → màn T14.
  paymentRequired,

  /// 403 — không đủ quyền; `CONSENT_REQUIRED` → màn đồng ý.
  forbidden,

  /// 404 — không tồn tại hoặc không được xem → màn trống.
  notFound,

  /// 409 — cần xác nhận / xung đột / đang xử lý.
  conflict,

  /// 410 — link mời hết hạn / đã dùng.
  gone,

  /// 422 — dữ liệu sai: lỗi tại trường ([ApiException.fieldErrors]).
  validation,

  /// 429 — chờ [ApiException.retryAfter] rồi thử lại.
  rateLimited,

  /// 5xx — lỗi hệ thống, bảo trì.
  server;

  static ApiErrorKind fromStatus(int? status) => switch (status) {
    null => network,
    401 => unauthenticated,
    402 => paymentRequired,
    403 => forbidden,
    404 => notFound,
    409 => conflict,
    410 => gone,
    422 => validation,
    429 => rateLimited,
    >= 500 => server,
    _ => badRequest,
  };
}

/// Lỗi từ TeachHub API theo định dạng `{ code, message, details?, errors?, requestId }`
/// (spec §5.6). Client tra thông điệp tiếng Việt theo [code]; [message] của server
/// chỉ là dự phòng.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.wireCode,
    required this.status,
    this.message,
    this.details = const {},
    this.fieldErrors = const {},
    this.requestId,
    this.retryAfterHeader,
  });

  /// Không có phản hồi từ API (mất mạng, timeout, hủy).
  const ApiException.network()
    : code = ApiErrorCode.unknown,
      wireCode = null,
      status = null,
      message = null,
      details = const {},
      fieldErrors = const {},
      requestId = null,
      retryAfterHeader = null;

  /// Phản hồi thành công nhưng sai hình dạng hợp đồng (thiếu body, sai kiểu).
  const ApiException.unexpected()
    : code = ApiErrorCode.unknown,
      wireCode = null,
      status = 500,
      message = null,
      details = const {},
      fieldErrors = const {},
      requestId = null,
      retryAfterHeader = null;

  /// Lỗi gọi API từ [DioException]: có phản hồi → đọc body lỗi; không có
  /// (mất mạng, timeout) → [ApiException.network]; lỗi khác → `null`.
  static ApiException? fromDio(Object? error) {
    if (error is ApiException) return error;
    if (error is! DioException) return null;
    final response = error.response;
    if (response == null) return const ApiException.network();
    return ApiException.fromResponse(
      response.statusCode,
      response.data,
      retryAfterHeader: response.headers.value('retry-after'),
    );
  }

  /// Đọc body lỗi; body không đúng định dạng vẫn ra một [ApiException] theo [status].
  factory ApiException.fromResponse(
    int? status,
    Object? body, {
    String? retryAfterHeader,
  }) {
    final map = body is Map ? body : const {};
    final wire = map['code'] is String ? map['code'] as String : null;
    final details = map['details'];
    final errors = map['errors'];
    return ApiException(
      code: ApiErrorCode.fromWire(wire),
      wireCode: wire,
      status: status,
      message: map['message'] is String ? map['message'] as String : null,
      details: details is Map ? details.cast<String, Object?>() : const {},
      fieldErrors: errors is Map
          ? {
              for (final MapEntry(:key, :value) in errors.entries)
                if (value is List) '$key': value.map((e) => '$e').toList(),
            }
          : const {},
      requestId: map['requestId'] is String ? map['requestId'] as String : null,
      retryAfterHeader: retryAfterHeader,
    );
  }

  final ApiErrorCode code;

  /// `code` nguyên văn (giữ cả mã [ApiErrorCode.unknown] để log/hiển thị dự phòng).
  final String? wireCode;

  /// HTTP status; `null` khi không có phản hồi.
  final int? status;
  final String? message;
  final Map<String, Object?> details;

  /// Chỉ có với `VALIDATION_FAILED`: `{ "dates.end": ["…"] }`.
  final Map<String, List<String>> fieldErrors;
  final String? requestId;
  final String? retryAfterHeader;

  ApiErrorKind get kind => ApiErrorKind.fromStatus(status);

  /// Thời gian chờ của 429: `details.retryAfterSec`, không có thì header `Retry-After` (giây).
  Duration? get retryAfter {
    final fromBody = details['retryAfterSec'];
    final seconds = fromBody is num
        ? fromBody.toInt()
        : int.tryParse(retryAfterHeader ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  /// Client chỉ tự thử lại khi mất mạng, 5xx, 409 `IDEMPOTENCY_IN_PROGRESS` và 429 (spec §5.6).
  bool get retryable =>
      kind == ApiErrorKind.network ||
      kind == ApiErrorKind.server ||
      kind == ApiErrorKind.rateLimited ||
      code == ApiErrorCode.idempotencyInProgress;

  @override
  String toString() =>
      'ApiException($status ${wireCode ?? 'network'}, requestId: $requestId)';
}
