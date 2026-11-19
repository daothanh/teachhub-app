import 'package:app/core/background/background_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runBackgroundTask', () {
    test('chưa đăng nhập: không đồng bộ, không xin thử lại', () async {
      var synced = false;
      final ok = await runBackgroundTask(
        task: outboxSyncTask,
        hasSession: () async => false,
        sync: () async {
          synced = true;
          return true;
        },
      );
      expect(synced, isFalse);
      expect(ok, isTrue);
    });

    test(
      'đã đăng nhập: chạy một lượt và trả kết quả để hệ điều hành thử lại',
      () async {
        for (final result in [true, false]) {
          var runs = 0;
          final ok = await runBackgroundTask(
            task: outboxSyncTask,
            hasSession: () async => true,
            sync: () async {
              runs++;
              return result;
            },
          );
          expect(runs, 1);
          expect(ok, result);
        }
      },
    );

    test('tác vụ lạ bị bỏ qua', () async {
      var checked = false;
      final ok = await runBackgroundTask(
        task: 'iOSPerformFetch',
        hasSession: () async {
          checked = true;
          return true;
        },
        sync: () async => false,
      );
      expect(checked, isFalse);
      expect(ok, isTrue);
    });
  });
}
