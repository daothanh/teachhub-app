import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart';
import 'package:tasco_storage/tasco_storage.dart';

part 'teacher_database.g.dart';

/// Thay đổi cục bộ chờ đẩy lên server (spec §6.4). SyncEngine đọc bảng này
/// theo thứ tự [id].
@DataClassName('OutboxMutation')
class OutboxMutations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UUID do app sinh; API áp dụng mỗi mutation đúng một lần.
  TextColumn get clientMutationId => text().unique()();
  TextColumn get entity => text()();

  /// JSON của thay đổi.
  TextColumn get payload => text()();
  DateTimeColumn get clientUpdatedAt => dateTime()();
}

/// CSDL cục bộ của mini-app `teacher`, mã hóa bằng SQLite3MultipleCiphers
/// (docs/adr/0001-encrypted-local-database.md).
@DriftDatabase(tables: [OutboxMutations])
class TeacherDatabase extends _$TeacherDatabase {
  TeacherDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  /// Mở `teacher.sqlite` với khóa 256-bit lấy từ [keyStore] (Keychain/
  /// Keystore), sinh khóa ở lần mở đầu.
  static Future<TeacherDatabase> openEncrypted(KeyValueStore keyStore) async {
    final key = await databaseKey(keyStore);
    return TeacherDatabase(
      driftDatabase(
        name: 'teacher',
        native: DriftNativeOptions(setup: encryptionSetup(key)),
      ),
    );
  }
}

const _keyName = 'teacher.db_key';

/// Khóa CSDL dạng hex 64 ký tự; sinh bằng CSPRNG và lưu ở lần đầu.
Future<String> databaseKey(KeyValueStore store, {Random? random}) async {
  final stored = await store.read(_keyName);
  if (stored != null && stored.length == 64) return stored;
  final rng = random ?? Random.secure();
  final key = List.generate(
    32,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  await store.write(_keyName, key);
  return key;
}

/// Đặt khóa trước mọi truy vấn. Không có bản SQLite hỗ trợ mã hóa thì dừng
/// hẳn (kể cả bản release) — dữ liệu có tên học sinh không được ghi rõ.
void Function(CommonDatabase) encryptionSetup(String hexKey) => (db) {
  if (db.select('PRAGMA cipher;').isEmpty) {
    throw StateError('SQLite3MultipleCiphers is not bundled; refusing to open');
  }
  db.execute("PRAGMA hexkey = '$hexKey';");
};
