import 'dart:async';
import 'dart:convert';

import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../data/local_db/teacher_local_data.dart';

/// Việc onboarding đã làm trên server mà bước chưa được ghi `done`, lưu bền
/// vững để kill app giữa chừng không tạo trùng (lớp ở bước 1, học viên ở bước 2).
class OnboardingDraft {
  const OnboardingDraft({this.classId, this.studentId, this.keys = const {}});

  /// Lớp tạo ở bước 1; bước 2 và 3 dùng đúng lớp này.
  final String? classId;

  /// Học viên đã tạo ở bước 2 mà bước chưa `done` (ghi danh tiếp).
  final String? studentId;

  /// Khóa Idempotency-Key của lệnh ghi đang dở, theo `op`.
  final Map<String, ({String draft, String key})> keys;

  OnboardingDraft copyWith({
    String? classId,
    String? studentId,
    bool clearStudent = false,
    Map<String, ({String draft, String key})>? keys,
  }) => OnboardingDraft(
    classId: classId ?? this.classId,
    studentId: clearStudent ? null : (studentId ?? this.studentId),
    keys: keys ?? this.keys,
  );
}

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
