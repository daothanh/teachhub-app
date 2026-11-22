import 'package:flutter_test/flutter_test.dart';
import 'package:parent/features/family/cubit/family_cubit.dart';
import 'package:parent/features/family/data/family_models.dart';
import 'package:parent/features/family/data/family_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _Repo implements FamilyRepository {
  List<FamilyStudent> children = const [
    FamilyStudent(id: 'a', fullName: 'Minh Anh', classes: []),
  ];
  bool fail = false;
  final weekCalls = <String>[];

  @override
  Future<List<FamilyStudent>> students() async {
    if (fail) throw const ApiException.network();
    return children;
  }

  @override
  Future<AttendanceWeek> attendance(String studentId, {DateTime? week}) async {
    weekCalls.add(studentId);
    return AttendanceWeek(
      studentId: studentId,
      weekStart: DateTime(2026, 12, 14),
      weekEnd: DateTime(2026, 12, 20),
      summary: const AttendanceSummary(
        present: 0,
        late: 0,
        excused: 0,
        unexcused: 0,
        notRecorded: 0,
        upcoming: 0,
      ),
      sessions: const [],
    );
  }
}

void main() {
  test(
    'hết con sau khi làm mới: bỏ id cũ, không tải chuyên cần cho id cũ',
    () async {
      final repo = _Repo();
      final c = FamilyCubit(repo);
      addTearDown(c.close);
      await c.load();
      expect(c.state.selectedId, 'a');
      expect(repo.weekCalls, ['a']);

      repo.children = const [];
      await c.load();
      expect(c.state.selectedId, isNull);
      expect(c.state.week, isNull);
      expect(repo.weekCalls, ['a']);
    },
  );

  test(
    'làm mới lỗi khi đã có dữ liệu: giữ màn, báo refreshFailed mỗi lần',
    () async {
      final repo = _Repo();
      final c = FamilyCubit(repo);
      addTearDown(c.close);
      await c.load();

      final seen = <bool>[];
      final sub = c.stream.listen((s) => seen.add(s.refreshFailed));
      addTearDown(sub.cancel);
      repo.fail = true;
      await c.load();
      await c.load();
      await Future<void>.delayed(Duration.zero);

      expect(c.state.status, FamilyStatus.ready);
      expect(c.state.students, hasLength(1));
      // Lần lỗi thứ hai vẫn phát lại tín hiệu (xóa rồi đặt lại).
      expect(seen, [true, false, true]);
    },
  );

  test('tải đầu lỗi: failure, không báo refreshFailed', () async {
    final c = FamilyCubit(_Repo()..fail = true);
    addTearDown(c.close);
    await c.load();
    expect(c.state.status, FamilyStatus.failure);
    expect(c.state.refreshFailed, isFalse);
  });
}
