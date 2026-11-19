import 'package:app/features/auth/logout_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> calls;
  late int pending;

  LogoutService build() => LogoutService(
    logout: () async => calls.add('logout'),
    pendingCount: () async => pending,
    wipeLocalData: () async => calls.add('wipe'),
  );

  setUp(() {
    calls = [];
    pending = 0;
  });

  group('logout', () {
    test('outbox trống: đăng xuất rồi xóa CSDL, không hỏi', () async {
      final done = await build().logout(
        confirmDiscard: (_) async => fail('không được hỏi khi outbox trống'),
      );
      expect(done, isTrue);
      expect(calls, ['logout', 'wipe']);
    });

    test('còn dữ liệu, người dùng xác nhận: đăng xuất và xóa', () async {
      pending = 3;
      int? asked;
      final done = await build().logout(
        confirmDiscard: (n) async {
          asked = n;
          return true;
        },
      );
      expect(asked, 3);
      expect(done, isTrue);
      expect(calls, ['logout', 'wipe']);
    });

    test('còn dữ liệu, người dùng ở lại: không đăng xuất, không xóa', () async {
      pending = 2;
      final done = await build().logout(confirmDiscard: (_) async => false);
      expect(done, isFalse);
      expect(calls, isEmpty);
    });
  });

  group('onSessionExpired (forceLogout)', () {
    test('outbox trống: xóa CSDL', () async {
      expect(await build().onSessionExpired(), isTrue);
      expect(calls, ['wipe']);
    });

    test('còn dữ liệu: giữ CSDL để đồng bộ sau', () async {
      pending = 1;
      expect(await build().onSessionExpired(), isFalse);
      expect(calls, isEmpty);
    });
  });
}
