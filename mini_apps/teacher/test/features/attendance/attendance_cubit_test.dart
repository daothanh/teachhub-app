import 'dart:async';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/attendance/cubit/attendance_cubit.dart';
import 'package:teacher/features/attendance/data/attendance_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_attendance_repository.dart';

class _Analytics implements AttendanceAnalytics {
  final events = <({int students, int absent, bool edit})>[];
  @override
  void attendanceSaved({
    required int students,
    required int absent,
    required bool edit,
  }) => events.add((students: students, absent: absent, edit: edit));
}

Future<AttendanceCubit> open(
  FakeAttendanceRepository repo, {
  AttendanceAnalytics? analytics,
}) async {
  final cubit = AttendanceCubit(
    repo,
    sessionId,
    analytics: analytics ?? _Analytics(),
  );
  await cubit.load();
  await Future<void>.delayed(Duration.zero);
  return cubit;
}

void main() {
  List<SheetStudent> roster(int n) => [for (var i = 1; i <= n; i++) student(i)];

  test('AC-6: mặc định mọi em Có mặt, chạm đổi vòng đủ 4 trạng thái', () async {
    final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)));
    final cubit = await open(repo);
    addTearDown(cubit.close);
    final s1 = cubit.state.sheet!.students.first;

    expect(cubit.state.statusOf(s1), AttendanceStatus.present);
    final seen = <AttendanceStatus>[];
    for (var i = 0; i < 4; i++) {
      cubit.tap('st-1');
      seen.add(cubit.state.statusOf(s1));
    }
    expect(seen, [
      AttendanceStatus.late,
      AttendanceStatus.excused,
      AttendanceStatus.unexcused,
      AttendanceStatus.present,
    ]);
    // Em còn lại không đổi.
    expect(
      cubit.state.statusOf(cubit.state.sheet!.students.last),
      AttendanceStatus.present,
    );
  });

  test(
    'AC-8: lớp 20 em đủ mặt — Lưu ngay (không chạm), ghi đủ 20 em',
    () async {
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(20)));
      final cubit = await open(repo);
      addTearDown(cubit.close);

      expect(cubit.state.canSave, isTrue);
      await cubit.save();

      expect(repo.saves.single.entries, hasLength(20));
      expect(
        repo.saves.single.entries.every(
          (e) => e.status == AttendanceStatus.present,
        ),
        isTrue,
      );
      expect(cubit.state.saved, isTrue);
    },
  );

  test('AC-8: 3 em vắng (mỗi em chạm 2 lần) rồi Lưu', () async {
    final repo = FakeAttendanceRepository(sheet: sheetOf(roster(20)));
    final cubit = await open(repo);
    addTearDown(cubit.close);

    // Có mặt → Muộn → Vắng có phép: 2 chạm.
    for (final n in [1, 2, 3]) {
      cubit
        ..tap('st-$n')
        ..tap('st-$n');
    }
    await cubit.save();

    final byId = {for (final e in repo.saves.single.entries) e.studentId: e};
    expect(byId['st-1']!.status, AttendanceStatus.excused);
    expect(byId['st-4']!.status, AttendanceStatus.present);
    expect(byId, hasLength(20));
  });

  test(
    'AC-7: Lưu chỉ ghi cục bộ, không gọi làm mới (không chờ mạng)',
    () async {
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(3)));
      final cubit = await open(repo);
      addTearDown(cubit.close);
      final refreshes = repo.refreshSheetCalls;

      await cubit.save();

      expect(repo.refreshSheetCalls, refreshes);
      expect(repo.saves, hasLength(1));
    },
  );

  test(
    'buổi đã điểm danh, chưa đổi gì: Lưu tắt; đổi một em thì chỉ ghi em đó',
    () async {
      final repo = FakeAttendanceRepository(
        sheet: sheetOf([
          student(1, status: AttendanceStatus.present),
          student(2, status: AttendanceStatus.present),
        ]),
      );
      final cubit = await open(repo);
      addTearDown(cubit.close);
      expect(cubit.state.canSave, isFalse);

      cubit.tap('st-2');
      expect(cubit.state.canSave, isTrue);
      await cubit.save();
      expect(repo.saves.single.entries.map((e) => e.studentId), ['st-2']);
    },
  );

  test('AC-9: ghi chú cắt ở 500 ký tự, rỗng thành null', () async {
    final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)));
    final cubit = await open(repo);
    addTearDown(cubit.close);

    cubit
      ..setNote('st-1', 'a' * 600)
      ..setNote('st-2', '');
    await cubit.save();

    final byId = {for (final e in repo.saves.single.entries) e.studentId: e};
    expect(byId['st-1']!.note, hasLength(attendanceNoteMax));
    expect(byId['st-2']!.note, isNull);
  });

  test(
    'AC-10: phát attendance_saved kèm số lượng, không có tên hay ghi chú',
    () async {
      final analytics = _Analytics();
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(4)));
      final cubit = await open(repo, analytics: analytics);
      addTearDown(cubit.close);

      cubit
        ..tap('st-1')
        ..tap('st-1') // vắng có phép
        ..tap('st-2'); // muộn: chưa tính vắng
      await cubit.save();

      expect(analytics.events, [(students: 4, absent: 1, edit: false)]);
    },
  );

  test(
    'AC-11: banner từ chối/lô lỗi lấy từ sheet; discardFailed gọi repo',
    () async {
      final repo = FakeAttendanceRepository(
        sheet: sheetOf([
          student(1, rejected: 'ATTENDANCE_EDIT_WINDOW_CLOSED'),
          student(2),
        ], batchErrorCode: 'SESSION_CANCELLED'),
      );
      final cubit = await open(repo);
      addTearDown(cubit.close);

      expect(cubit.state.sheet!.hasFailure, isTrue);
      await cubit.discardFailed();
      expect(repo.discards, [sessionId]);
    },
  );

  group('AC-12: hạn sửa', () {
    test(
      'quá editableUntil theo giờ server: chỉ xem, chạm và Lưu đều vô hiệu',
      () async {
        final repo = FakeAttendanceRepository(
          sheet: sheetOf(
            roster(2),
            editableUntil: DateTime.utc(2026, 11, 17),
            canEdit: true, // cache cũ còn nói được sửa, giờ server đã quá hạn
          ),
        );
        final cubit = await open(repo);
        addTearDown(cubit.close);

        expect(cubit.state.readOnly, ReadOnlyReason.windowClosed);
        cubit.tap('st-1');
        expect(cubit.state.drafts, isEmpty);
        expect(cubit.state.canSave, isFalse);
      },
    );

    test('còn hạn: sửa được', () async {
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)));
      final cubit = await open(repo);
      addTearDown(cubit.close);
      expect(cubit.state.readOnly, isNull);
    });

    test('server nói canEdit=false và chưa có hạn: chỉ xem', () async {
      final repo = FakeAttendanceRepository(
        sheet: SessionSheet(
          sessionId: sessionId,
          className: 'x',
          sessionDate: '2026-11-01',
          startTime: '08:00',
          cancelled: false,
          canEdit: false,
          editableUntil: null,
          students: roster(1),
        ),
      );
      final cubit = await open(repo);
      addTearDown(cubit.close);
      expect(cubit.state.readOnly, ReadOnlyReason.windowClosed);
    });

    test('buổi đã hủy: chỉ xem', () async {
      final repo = FakeAttendanceRepository(
        sheet: sheetOf(roster(2), cancelled: true),
      );
      final cubit = await open(repo);
      addTearDown(cubit.close);
      expect(cubit.state.readOnly, ReadOnlyReason.cancelled);
      expect(cubit.state.canSave, isFalse);
    });

    test('sửa buổi đã điểm danh: analytics đánh dấu edit', () async {
      final analytics = _Analytics();
      final repo = FakeAttendanceRepository(
        sheet: sheetOf([student(1, status: AttendanceStatus.present)]),
      );
      final cubit = await open(repo, analytics: analytics);
      addTearDown(cubit.close);
      cubit.tap('st-1');
      await cubit.save();
      expect(analytics.events.single.edit, isTrue);
    });
  });

  test(
    'mất mạng khi làm mới: vẫn hiện danh sách đã lưu kèm cờ ngoại tuyến',
    () async {
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)))
        ..refreshError = const ApiException.network();
      final cubit = await open(repo);
      addTearDown(cubit.close);

      expect(cubit.state.load, AttendanceLoad.ready);
      expect(cubit.state.offline, isTrue);
      expect(cubit.state.sheet!.students, hasLength(2));
    },
  );

  test('chưa có danh sách và làm mới lỗi: màn lỗi', () async {
    final repo = FakeAttendanceRepository()
      ..refreshError = const ApiException.network();
    final cubit = await open(repo);
    addTearDown(cubit.close);
    expect(cubit.state.load, AttendanceLoad.failure);
  });

  test(
    'lưu lỗi (ghi CSDL): không đóng màn, báo saveFailed, giữ thay đổi',
    () async {
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)))
        ..saveError = StateError('db');
      final cubit = await open(repo);
      addTearDown(cubit.close);
      cubit.tap('st-1');
      await cubit.save();
      expect(cubit.state.saveFailed, isTrue);
      expect(cubit.state.saved, isFalse);
      expect(cubit.state.drafts, isNotEmpty);
    },
  );

  test('đóng cubit giữa lúc đang lưu: không emit sau close', () async {
    final gate = Completer<void>();
    final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)))
      ..saveGate = gate;
    final cubit = await open(repo);
    final saving = cubit.save();
    await cubit.close();
    gate.complete();
    await saving; // không ném StateError "Cannot emit new states after calling close"
    expect(cubit.isClosed, isTrue);
  });

  group('vòng sửa', () {
    test(
      'lỗi không phải ApiException khi làm mới → màn lỗi có Thử lại',
      () async {
        final repo = FakeAttendanceRepository()
          ..refreshError = StateError('db');
        final cubit = await open(repo);
        addTearDown(cubit.close);
        expect(cubit.state.load, AttendanceLoad.failure);
        repo.refreshError = null;
        repo.setSheet(sheetOf(roster(1)));
        await cubit.refresh();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.load, AttendanceLoad.ready);
      },
    );

    test(
      'stream lỗi (CSDL đóng): không uncaught, phát trạng thái lỗi',
      () async {
        final repo = FakeAttendanceRepository()
          ..streamError = StateError('closed');
        final cubit = AttendanceCubit(repo, sessionId, analytics: _Analytics());
        addTearDown(cubit.close);
        final states = <AttendanceState>[];
        final sub = cubit.stream.listen(states.add);
        addTearDown(sub.cancel);
        await cubit.load();
        await Future<void>.delayed(Duration.zero);
        expect(states.any((s) => s.error != null), isTrue);
      },
    );

    test('discardFailed lỗi: bắt lại, báo error', () async {
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(1)))
        ..discardError = StateError('db');
      final cubit = await open(repo);
      addTearDown(cubit.close);
      await cubit.discardFailed();
      expect(cubit.state.error, isNotNull);
    });

    test('hết hạn đúng lúc: timer tính lại readOnly theo giờ server', () async {
      final repo = FakeAttendanceRepository(
        sheet: sheetOf(
          roster(1),
          editableUntil: DateTime.utc(2026, 11, 18, 10, 0, 0, 50),
        ),
      )..advanceOnRead = const Duration(milliseconds: 100);
      final cubit = await open(repo);
      addTearDown(cubit.close);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(cubit.state.readOnly, ReadOnlyReason.windowClosed);
      expect(cubit.state.canSave, isFalse);
    });

    test('ghi chú cắt theo ký tự, không xé đôi emoji', () async {
      final repo = FakeAttendanceRepository(sheet: sheetOf(roster(1)));
      final cubit = await open(repo);
      addTearDown(cubit.close);
      cubit.setNote('st-1', '👨‍👩‍👧' * 600);
      expect(
        cubit.state.drafts['st-1']!.note!.characters.length,
        attendanceNoteMax,
      );
    });
  });
}
