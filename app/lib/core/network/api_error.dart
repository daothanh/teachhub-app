import 'package:dio/dio.dart';

/// Mã lỗi `code` trong body lỗi của TeachHub API (`{ code, message, ... }`,
/// spec §5.6), hoặc `null` khi lỗi không đến từ API (mất mạng, timeout…).
String? apiErrorCode(Object? error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is Map && data['code'] is String) return data['code'] as String;
  return null;
}

/// `details` trong body lỗi (vd. `retryAfterSec` của 429 `OTP_LOCKED`), hoặc
/// map rỗng khi không có.
Map<String, Object?> apiErrorDetails(Object? error) {
  if (error is! DioException) return const {};
  final data = error.response?.data;
  final details = data is Map ? data['details'] : null;
  return details is Map ? details.cast<String, Object?>() : const {};
}
