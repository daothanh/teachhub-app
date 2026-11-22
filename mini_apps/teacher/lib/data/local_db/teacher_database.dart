import 'dart:developer' as developer;
import 'dart:io';
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

  /// v2: số lần SyncEngine đã gửi thất bại (để giãn thời gian thử lại).
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// v2: mã lỗi lần gửi gần nhất (không lưu body/PII).
  TextColumn get lastError => text().nullable()();

  /// v3: buổi và học viên của mutation (null ở dòng cũ của bản spike v2 —
  /// SyncEngine bỏ qua dòng đó). Mỗi lô gửi lên server là một buổi.
  TextColumn get sessionId => text().nullable()();
  TextColumn get studentId => text().nullable()();

  /// v3: `Idempotency-Key` và `deviceTime` của lô đã gom các dòng này. Lưu lại để
  /// gửi lại sau khi mất phản hồi (kể cả sau khi app bị kill) vẫn đúng khóa và
  /// đúng thân request, server mới nhận ra là cùng lô.
  TextColumn get batchKey => text().nullable()();
  DateTimeColumn get batchDeviceTime => dateTime().nullable()();
}

/// v3: buổi học trong cache ngoại tuyến (`GET /sessions`, `GET /sessions/{id}/attendance`).
/// Chỉ cột tối thiểu theo ADR-0001: không SĐT, ngày sinh, phụ huynh.
@DataClassName('CachedSession')
class CachedSessions extends Table {
  TextColumn get id => text()();
  TextColumn get classId => text()();
  TextColumn get className => text()();

  /// Ngày buổi học theo múi giờ tenant, `yyyy-MM-dd`.
  TextColumn get sessionDate => text()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();

  /// `planned` | `taught` | `cancelled`.
  TextColumn get status => text()();
  BoolColumn get isMakeup => boolean()();

  /// v4: offset UTC của tenant (phút) lấy từ `startsAt` của server, để hiện giờ
  /// tường đúng khi ngoại tuyến. null ở dòng cũ: dùng giờ máy.
  IntColumn get tzOffsetMinutes => integer().nullable()();

  /// v5: lý do hủy của buổi (nếu có), để lịch ngoại tuyến vẫn hiện được.
  TextColumn get cancelReason => text().nullable()();

  /// Chỉ có sau khi tải điểm danh của buổi; null = chưa tải danh sách.
  BoolColumn get canEdit => boolean().nullable()();
  DateTimeColumn get editableUntil => dateTime().nullable()();
  DateTimeColumn get rosterFetchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// v3: học viên của buổi và trạng thái điểm danh đã biết (tên là PII, CSDL đã mã hóa).
@DataClassName('CachedAttendance')
class CachedAttendances extends Table {
  TextColumn get sessionId => text()();
  TextColumn get studentId => text()();
  TextColumn get fullName => text()();

  /// `present` | `late` | `excused` | `unexcused`; null = chưa điểm danh.
  TextColumn get status => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get clientUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId, studentId};
}

/// CSDL cục bộ của mini-app `teacher`, mã hóa bằng SQLite3MultipleCiphers
/// (docs/adr/0001-encrypted-local-database.md).
@DriftDatabase(tables: [OutboxMutations, CachedSessions, CachedAttendances])
class TeacherDatabase extends _$TeacherDatabase {
  TeacherDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  /// Chỉ thêm (expand), không xóa/đổi tên cột — giống quy ước migration backend.
  /// Mỗi bước có test trong test/data/teacher_migration_test.dart.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(outboxMutations, outboxMutations.attemptCount);
        await m.addColumn(outboxMutations, outboxMutations.lastError);
      }
      if (from < 3) {
        await m.addColumn(outboxMutations, outboxMutations.sessionId);
        await m.addColumn(outboxMutations, outboxMutations.studentId);
        await m.addColumn(outboxMutations, outboxMutations.batchKey);
        await m.addColumn(outboxMutations, outboxMutations.batchDeviceTime);
        await m.createTable(cachedSessions);
        await m.createTable(cachedAttendances);
        // Dòng của spike v2 (chưa phát hành) không có buổi/học viên nên không
        // gửi được: bỏ.
        await customStatement(
          'DELETE FROM outbox_mutations WHERE session_id IS NULL',
        );
      }
      // from < 3: createTable ở trên đã tạo bảng với cột tzOffsetMinutes.
      if (from == 3) {
        await m.addColumn(cachedSessions, cachedSessions.tzOffsetMinutes);
      }
      // v5 cancelReason; from < 3 thì createTable ở trên đã có cột.
      if (from >= 3 && from < 5) {
        await m.addColumn(cachedSessions, cachedSessions.cancelReason);
      }
    },
  );

  /// Mở `teacher.sqlite` với khóa 256-bit lấy từ [keyStore] (Keychain/
  /// Keystore), sinh khóa ở lần mở đầu. [directory] là thư mục drift_flutter
  /// lưu file (xem [openingDatabaseKey]).
  static Future<TeacherDatabase> openEncrypted(
    KeyValueStore keyStore, {
    required Future<Directory> Function() directory,
  }) async =>
      openWithKey(await openingDatabaseKey(keyStore, await directory()));

  /// Mở với khóa đã có. Isolate nền dùng đường này (khóa đọc bằng
  /// [readDatabaseKey]) để không bao giờ sinh khóa mới.
  static TeacherDatabase openWithKey(String key) => TeacherDatabase(
    driftDatabase(
      name: teacherDatabaseName,
      native: DriftNativeOptions(setup: encryptionSetup(key)),
    ),
  );
}

const _keyName = 'teacher.db_key';

/// Tên CSDL cho `driftDatabase`; file trên máy là [teacherDatabaseFile].
const teacherDatabaseName = 'teacher';
const teacherDatabaseFile = '$teacherDatabaseName.sqlite';

/// Prefix của `lastError` cho mutation bị từ chối: không gửi lại nữa.
const rejectedPrefix = 'rejected:';

/// Prefix của `lastError` cho mutation thuộc lô lỗi cả lô: không gửi lại nữa.
const batchFailedPrefix = 'batch:';

/// Mutation đang chờ gửi: chưa bị từ chối và không thuộc lô lỗi.
Expression<bool> outboxPending($OutboxMutationsTable r) =>
    r.lastError.isNull() |
    (r.lastError.like('$rejectedPrefix%').not() &
        r.lastError.like('$batchFailedPrefix%').not());

/// Số mutation đang chờ gửi (khớp chip "Chờ đồng bộ") = số buổi chưa đồng bộ.
Future<int> pendingOutboxCount(TeacherDatabase db) =>
    db.outboxMutations.count(where: outboxPending).getSingle();

/// Số mutation bị từ chối hoặc thuộc lô lỗi: giữ lại để người dùng xem, sẽ
/// không bao giờ tự gửi lại.
Future<int> failedOutboxCount(TeacherDatabase db) =>
    db.outboxMutations.count(where: (r) => outboxPending(r).not()).getSingle();

/// Bỏ các mutation bị từ chối/lô lỗi (người dùng đã xem). Trả số dòng đã bỏ.
Future<int> discardFailedOutbox(TeacherDatabase db) =>
    (db.delete(db.outboxMutations)..where((r) => outboxPending(r).not())).go();

/// Xóa CSDL `teacher` (file + WAL/SHM/journal) và khóa của nó — dùng khi đăng
/// xuất, sau khi outbox đã trống (spec §6.4). [dir] là thư mục drift_flutter
/// lưu file (`getApplicationDocumentsDirectory()`). Phải đóng CSDL trước.
Future<void> deleteTeacherDatabase(
  KeyValueStore keyStore,
  Directory dir,
) async {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final file = File('${dir.path}/$teacherDatabaseFile$suffix');
    if (file.existsSync()) await file.delete();
  }
  await keyStore.delete(_keyName);
}

/// Khóa đã lưu, hoặc `null` nếu chưa có / hỏng. Không sinh khóa.
Future<String?> readDatabaseKey(KeyValueStore store) async {
  final stored = await store.read(_keyName);
  return stored != null && stored.length == 64 ? stored : null;
}

/// Khóa để mở CSDL ở app chính. Mất khóa mà file cũ còn (Android khôi phục
/// backup hay chuyển máy không mang theo Keystore, Keystore bị reset) thì file
/// đó không giải mã được nữa: xóa rồi tạo mới, thay vì mở bằng khóa mới và lỗi
/// mãi, khóa cả mini-app. Outbox trong file cũ vốn không đọc được nên không mất
/// thêm gì; cache tải lại từ server.
Future<String> openingDatabaseKey(KeyValueStore store, Directory dir) async {
  final stored = await readDatabaseKey(store);
  if (stored != null) return stored;
  if (File('${dir.path}/$teacherDatabaseFile').existsSync()) {
    developer.log(
      'Teacher DB còn file nhưng mất khóa, tạo lại CSDL',
      name: 'teacher',
    );
  }
  await deleteTeacherDatabase(store, dir);
  return databaseKey(store);
}

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
  // App và isolate nền có thể cùng mở file: WAL cho đọc/ghi song song, chờ
  // tối đa 5 giây khi bị khóa thay vì lỗi SQLITE_BUSY.
  // busy_timeout đặt trước: chính việc đổi sang WAL cũng cần khóa.
  db.execute('PRAGMA busy_timeout = 5000;');
  db.execute('PRAGMA journal_mode = WAL;');
};
