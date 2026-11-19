import 'dart:async';

import 'package:app/bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gỡ token push trước khi xóa phiên', () async {
    var called = false;
    await unregisterPushBeforeLogout(() async => called = true);
    expect(called, isTrue);
  });

  test('lỗi mạng không chặn đăng xuất', () async {
    await unregisterPushBeforeLogout(() async => throw Exception('offline'));
  });

  test('treo quá hạn thì bỏ qua', () async {
    await unregisterPushBeforeLogout(
      () => Completer<void>().future,
      timeout: const Duration(milliseconds: 10),
    );
  });

  test('không có director (development thiếu Firebase): bỏ qua', () async {
    await unregisterPushBeforeLogout(null);
  });

  test('deleteFcmToken gọi xóa token và nuốt lỗi', () async {
    var called = false;
    await deleteFcmToken(delete: () async => called = true);
    expect(called, isTrue);
    await deleteFcmToken(delete: () async => throw Exception('no firebase'));
  });
}
