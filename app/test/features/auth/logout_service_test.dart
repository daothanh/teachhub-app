import 'package:app/features/auth/logout_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> calls;
  late List<Object> counts; // mỗi lần đếm lấy một phần tử; Exception = ném
  late int wipes;
  Object? wipeError;

  LogoutService build() => LogoutService(
    logout: () async => calls.add('logout'),
    pendingCount: () async {
      final next = counts.length > 1 ? counts.removeAt(0) : counts.first;
      if (next is Exception) throw next;
      return next as int;
    },
    wipeLocalData: () async {
      wipes++;
      await Future<void>.delayed(Duration.zero);
      if (wipeError != null) throw wipeError!;
      calls.add('wipe');
    },
  );

  setUp(() {
    calls = [];
    counts = [0];
    wipes = 0;
    wipeError = null;
  });

  test(
    'markWipePending/clearWipePending gọi hook; hook bỏ cờ lỗi chỉ ghi log',
    () async {
      final hooks = <String>[];
      final svc = LogoutService(
        logout: () async {},
        pendingCount: () async => 0,
        wipeLocalData: () async {},
        markWipePending: () async => hooks.add('mark'),
        clearWipePending: () async {
          hooks.add('clear');
          throw StateError('disk');
        },
      );
      await svc.markWipePending();
      await svc.clearWipePending();
      expect(hooks, ['mark', 'clear']);
    },
  );

  group('logout', () {
    test('outbox trống: đăng xuất rồi xóa CSDL, không hỏi', () async {
      final r = await build().logout(
        confirmDiscard: (_) async => fail('không được hỏi khi outbox trống'),
      );
      expect(r, LogoutResult.done);
      expect(calls, ['logout', 'wipe']);
    });

    test('còn dữ liệu, người dùng xác nhận: đăng xuất và xóa', () async {
      counts = [3];
      final asked = <int?>[];
      final r = await build().logout(
        confirmDiscard: (n) async {
          asked.add(n);
          return true;
        },
      );
      expect(asked, [3]);
      expect(r, LogoutResult.done);
      expect(calls, ['logout', 'wipe']);
    });

    test('còn dữ liệu, người dùng ở lại: không đăng xuất, không xóa', () async {
      counts = [2];
      final r = await build().logout(confirmDiscard: (_) async => false);
      expect(r, LogoutResult.cancelled);
      expect(calls, isEmpty);
    });

    test('không đọc được outbox: hỏi với null, xác nhận thì vẫn xóa', () async {
      counts = [Exception('db hỏng')];
      final asked = <int?>[];
      final r = await build().logout(
        confirmDiscard: (n) async {
          asked.add(n);
          return true;
        },
      );
      expect(asked, [null]);
      expect(r, LogoutResult.done);
      expect(calls, ['logout', 'wipe']);
    });

    test('không đọc được outbox, người dùng ở lại: không làm gì', () async {
      counts = [Exception('mất khóa')];
      final r = await build().logout(confirmDiscard: (_) async => false);
      expect(r, LogoutResult.cancelled);
      expect(calls, isEmpty);
    });

    test('số buổi tăng sau khi xác nhận: hỏi lại với số mới', () async {
      counts = [2, 5, 5];
      final asked = <int?>[];
      final r = await build().logout(
        confirmDiscard: (n) async {
          asked.add(n);
          return true;
        },
      );
      expect(asked, [2, 5]);
      expect(r, LogoutResult.done);
    });

    test('số tăng rồi người dùng ở lại ở lần hỏi lại: hủy xóa', () async {
      counts = [2, 5];
      var n = 0;
      final r = await build().logout(confirmDiscard: (_) async => ++n == 1);
      expect(r, LogoutResult.cancelled);
      expect(calls, isEmpty);
    });

    test('xóa lỗi sau khi đăng xuất: không ném, báo wipeFailed', () async {
      wipeError = StateError('disk');
      final r = await build().logout(confirmDiscard: (_) async => true);
      expect(r, LogoutResult.wipeFailed);
      expect(calls, ['logout']);
    });
  });

  group('onSessionExpired (forceLogout)', () {
    test('outbox trống: xóa CSDL', () async {
      expect(await build().onSessionExpired(), isTrue);
      expect(calls, ['wipe']);
    });

    test('còn dữ liệu: giữ CSDL để đồng bộ sau', () async {
      counts = [1];
      expect(await build().onSessionExpired(), isFalse);
      expect(calls, isEmpty);
    });

    test('không đọc được outbox: giữ CSDL, không ném', () async {
      counts = [Exception('db hỏng')];
      expect(await build().onSessionExpired(), isFalse);
      expect(wipes, 0);
    });

    test('xóa lỗi: không ném', () async {
      wipeError = StateError('disk');
      expect(await build().onSessionExpired(), isFalse);
    });

    test('nhiều sự kiện liên tiếp chỉ chạy một lần xóa', () async {
      final s = build();
      await Future.wait([
        s.onSessionExpired(),
        s.onSessionExpired(),
        s.onSessionExpired(),
      ]);
      expect(wipes, 1);
    });
  });
}
