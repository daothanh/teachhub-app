import 'dart:async';
import 'dart:convert';

import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../data/local_db/teacher_local_data.dart';

/// Việc onboarding đã làm trên server mà bước chưa được ghi `done`, lưu bền
/// vững để kill app giữa chừng không tạo trùng (lớp ở bước 1, học viên ở bước 2).
class OnboardingDraft {
  const OnboardingDraft({
    this.classId,
    this.studentId,
    this.studentName,
    this.studentPhone,
    this.added = const [],
    this.pendingFee,
    this.keys = const {},
  });

  /// Lớp tạo ở bước 1; bước 2 và 3 dùng đúng lớp này.
  final String? classId;

  /// Học viên đã tạo ở bước 2 mà bước chưa `done` (ghi danh tiếp).
  final String? studentId;

  /// Họ tên và SĐT phụ huynh của [studentId].
  final String? studentName;
  final String? studentPhone;

  /// Học viên đã thêm xong ở bước 2 (hiện lại khi mở lại app).
  final List<AddedStudent> added;

  /// Học phí "Trọn khóa" chọn ở bước 1: cần lịch học nên ghi ở bước 3.
  final ({String feeType, int amount})? pendingFee;

  /// Khóa Idempotency-Key của lệnh ghi đang dở, theo `op`.
  final Map<String, ({String draft, String key})> keys;

  OnboardingDraft copyWith({
    String? classId,
    String? studentId,
    String? studentName,
    String? studentPhone,
    bool clearStudent = false,
    List<AddedStudent>? added,
    ({String feeType, int amount})? pendingFee,
    bool clearPendingFee = false,
    Map<String, ({String draft, String key})>? keys,
  }) => OnboardingDraft(
    classId: classId ?? this.classId,
    studentId: clearStudent ? null : (studentId ?? this.studentId),
    studentName: clearStudent ? null : (studentName ?? this.studentName),
    studentPhone: clearStudent ? null : (studentPhone ?? this.studentPhone),
    added: added ?? this.added,
    pendingFee: clearPendingFee ? null : (pendingFee ?? this.pendingFee),
    keys: keys ?? this.keys,
  );
}

/// Một học viên đã thêm ở bước 2: họ tên và SĐT phụ huynh (nếu có).
typedef AddedStudent = ({String name, String? phone});

({String feeType, int amount})? _fee(Object? j) => j is Map
    ? (feeType: j['feeType'] as String, amount: j['amount'] as int)
    : null;

/// Kho [OnboardingDraft] trong kho khóa của máy. Gắn với chủ CSDL
/// ([TeacherLocalData.ownerKey]): người đăng nhập sau không thấy bản của người
/// trước; đăng xuất/xóa tài khoản xóa cả khóa này.
class OnboardingDraftStore {
  OnboardingDraftStore(this._kv);

  final KeyValueStore _kv;

  static const key = 'teacher.onboarding_draft';

  Future<void> _tail = Future.value();
  Future<T> _serial<T>(Future<T> Function() job) {
    final run = _tail.then((_) => job());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<OnboardingDraft> read() => _serial(_read);

  Future<OnboardingDraft> _read() async {
    try {
      final raw = await _kv.read(key);
      if (raw == null) return const OnboardingDraft();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['owner'] != await _kv.read(TeacherLocalData.ownerKey)) {
        return const OnboardingDraft();
      }
      return OnboardingDraft(
        classId: j['classId'] as String?,
        studentId: j['studentId'] as String?,
        studentName: j['studentName'] as String?,
        studentPhone: j['studentPhone'] as String?,
        added: [
          for (final a in (j['added'] as List? ?? const []))
            if (a is Map)
              (name: a['name'] as String, phone: a['phone'] as String?),
        ],
        pendingFee: _fee(j['pendingFee']),
        keys: {
          for (final e in (j['keys'] as Map? ?? const {}).entries)
            e.key as String: (
              draft: (e.value as Map)['draft'] as String,
              key: (e.value as Map)['key'] as String,
            ),
        },
      );
    } catch (_) {
      return const OnboardingDraft();
    }
  }

  /// Đọc, sửa, ghi lại tuần tự. Lỗi kho khóa (Keychain khóa màn hình) bị nuốt:
  /// mất bản nháp chỉ làm mất khả năng chống trùng sau kill app, không hỏng luồng.
  Future<void> update(OnboardingDraft Function(OnboardingDraft d) change) =>
      _serial(() async {
        try {
          final d = change(await _read());
          await _kv.write(
            key,
            jsonEncode({
              'owner': await _kv.read(TeacherLocalData.ownerKey),
              'classId': d.classId,
              'studentId': d.studentId,
              'studentName': d.studentName,
              'studentPhone': d.studentPhone,
              'added': [
                for (final a in d.added) {'name': a.name, 'phone': a.phone},
              ],
              'pendingFee': d.pendingFee == null
                  ? null
                  : {
                      'feeType': d.pendingFee!.feeType,
                      'amount': d.pendingFee!.amount,
                    },
              'keys': {
                for (final e in d.keys.entries)
                  e.key: {'draft': e.value.draft, 'key': e.value.key},
              },
            }),
          );
        } catch (_) {}
      });

  /// [DraftKeys] bền vững cho các `op` mang tiền tố [prefix] (`class`, `student`,
  /// `enroll`): khôi phục từ [seed] và ghi lại mỗi lần đổi.
  DraftKeys keys(OnboardingDraft seed, String prefix) => DraftKeys(
    seed: {
      for (final e in seed.keys.entries)
        if (e.key.startsWith('$prefix.'))
          e.key.substring(prefix.length + 1): e.value,
    },
    onChanged: (now) => unawaited(
      update(
        (d) => d.copyWith(
          keys: {
            for (final e in d.keys.entries)
              if (!e.key.startsWith('$prefix.')) e.key: e.value,
            for (final e in now.entries) '$prefix.${e.key}': e.value,
          },
        ),
      ),
    ),
  );
}
