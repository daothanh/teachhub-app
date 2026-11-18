import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Lỗi gọi TeachHub API dưới dạng [ApiException] (spec §5.6): có phản hồi →
/// đọc body `{ code, message, details?, errors?, requestId }`; không có phản hồi
/// (mất mạng, timeout) → [ApiException.network]; lỗi khác không phải từ API → `null`.
ApiException? apiException(Object? error) {
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
