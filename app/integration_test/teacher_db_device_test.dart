// S0-FL-07 / ADR-0001: CSDL `teacher` mã hóa sqlite3mc trên MÁY THẬT.
//
// Chạy hai lần (hai tiến trình) để kiểm giữ dữ liệu sau khởi động lại; pha write
// cần --no-uninstall (mặc định flutter test gỡ app sau khi chạy, xóa luôn dữ liệu):
//   flutter test integration_test/teacher_db_device_test.dart -d <máy> \
//     --flavor development --dart-define=PHASE=write --no-uninstall
//   flutter test integration_test/teacher_db_device_test.dart -d <máy> \
//     --flavor development --dart-define=PHASE=read
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';

const _phase = String.fromEnvironment('PHASE', defaultValue: 'write');
const _marker = 'restart-marker';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_phase == 'write') {
    test('ghi 20 bản ghi trong một giao dịch < 100 ms; file đã mã hóa', () async {
      final dir = await getApplicationDocumentsDirectory();
      final store = SecureStore();
      await deleteTeacherDatabase(store, dir); // bắt đầu sạch

      final db = await TeacherDatabase.openEncrypted(store);
      await db.into(db.outboxMutations).insert(_row(_marker));

      // 1 lần làm nóng + 10 lần đo. Một lần lưu điểm danh = 20 học sinh.
      Future<List<int>> measure(
        String tag,
        Future<void> Function(int run) write,
      ) async {
        final timings = <int>[];
        for (var run = 0; run <= 10; run++) {
          final sw = Stopwatch()..start();
          await write(run);
          sw.stop();
          if (run > 0) timings.add(sw.elapsedMicroseconds);
        }
        timings.sort();
        final ms = timings.map((us) => (us / 1000).toStringAsFixed(2)).toList();
        // ignore: avoid_print
        print(
          'TEACHER_DB $tag ms (sorted): $ms '
          'median=${ms[timings.length ~/ 2]} max=${ms.last}',
        );
        return timings;
      }

      // Từng lệnh insert trong một giao dịch: mỗi lệnh một lượt qua isolate của drift.
      await measure(
        '20 inserts/txn',
        (run) => db.transaction(() async {
          for (var i = 0; i < 20; i++) {
            await db.into(db.outboxMutations).insert(_row('t$run-s$i'));
          }
        }),
      );
      // Batch: cả 20 bản ghi một lượt — cách lưu điểm danh nên dùng.
      final batch = await measure(
        '20 rows batch',
        (run) => db.batch(
          (b) => b.insertAll(db.outboxMutations, [
            for (var i = 0; i < 20; i++) _row('b$run-s$i'),
          ]),
        ),
      );
      await db.close();
      // ignore: avoid_print
      print('TEACHER_DB device=${Platform.operatingSystemVersion}');
      expect(batch[batch.length ~/ 2], lessThan(100 * 1000));

      final file = File('${dir.path}/teacher.sqlite');
      expect(file.existsSync(), isTrue);
      expect(
        file.readAsBytesSync().take(15),
        isNot(equals('SQLite format 3'.codeUnits)),
        reason: 'file phải được mã hóa',
      );
    });
  } else {
    test(
      'sau khởi động lại: dữ liệu còn, schema đúng phiên bản hiện tại; xóa CSDL sạch file và khóa',
      () async {
        final dir = await getApplicationDocumentsDirectory();
        final store = SecureStore();

        final db = await TeacherDatabase.openEncrypted(store);
        final rows = await db.select(db.outboxMutations).get();
        expect(rows.map((r) => r.clientMutationId), contains(_marker));
        expect(
          rows,
          hasLength(1 + 2 * 11 * 20),
        ); // marker + 2 cách ghi × 11 lần × 20
        // Không hard-code số: user_version đã lưu phải khớp phiên bản của lớp.
        final stored = await db
            .customSelect('PRAGMA user_version')
            .map((r) => r.read<int>('user_version'))
            .getSingle();
        expect(stored, db.schemaVersion);
        await db.close();
        // ignore: avoid_print
        print('TEACHER_DB after restart rows=${rows.length}');

        await deleteTeacherDatabase(store, dir);
        expect(
          dir.listSync().where((f) => f.path.contains('teacher.sqlite')),
          isEmpty,
        );
        expect(await store.contains('teacher.db_key'), isFalse);
      },
    );
  }
}

OutboxMutationsCompanion _row(String id) => OutboxMutationsCompanion.insert(
  clientMutationId: id,
  entity: 'attendance',
  payload: '{"sessionId":"s-1","studentId":"st-$id","status":"present"}',
  clientUpdatedAt: DateTime.now().toUtc(),
);
