// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tasco_core/tasco_core.dart';

/// [LoggingInterceptor] của kit, che thêm dữ liệu cá nhân của học viên, phụ
/// huynh và trung tâm (họ tên, SĐT, ngày sinh, ghi chú…) khỏi log máy.
class TeachHubLoggingInterceptor extends LoggingInterceptor {
  static const _pii = {
    'fullname',
    'phone',
    'note',
    'school',
    'schoolclass',
    'centername',
    'dob',
    'email',
    'guardians',
    // Lời mời: token và mã ngắn là bí mật (US-0.12), không được vào log.
    'token',
    'code',
  };

  /// Thay giá trị của mọi khóa cá nhân bằng `***` (đệ quy), rồi áp che mặc định
  /// của kit (mật khẩu, token…).
  static Object? redactBody(Object? body) =>
      LoggingInterceptor.redact(_mask(body));

  static Object? _mask(Object? v) {
    if (v is Map) {
      return {
        for (final e in v.entries)
          e.key:
              _pii.contains(
                '${e.key}'.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), ''),
              )
              ? '***'
              : _mask(e.value),
      };
    }
    if (v is Iterable) return v.map(_mask).toList();
    return v;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      log('[REQUEST] ${options.method} => ${options.uri}', name: 'http');
      if (options.data != null) {
        log('[DATA] ${redactBody(options.data)}', name: 'http');
      }
    }
    handler.next(options);
  }
}
