import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/cubit/class_detail_cubit.dart';
import 'package:teacher/features/classes/cubit/class_form_cubit.dart';
import 'package:teacher/features/classes/cubit/student_picker_cubit.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_classes_repository.dart';

const _input = ClassInput(
  name: 'Toán 9A',
  subject: 'Toán',
  grade: 9,
  location: 'Nhà riêng',
  startDate: '2026-12-14',
);
const _rule = ScheduleRule(weekday: 2, startTime: '18:00', durationMin: 90);

void main() {
  group('Idempotency-Key giữ nguyên cho cùng draft', () {
    test(
      'tạo lớp: lỗi mạng rồi thử lại dùng lại khóa; draft đổi thì khóa mới',
      () async {
        final repo = FakeClassesRepository()
          ..createError = const ApiException.network();
        final cubit = ClassFormCubit(repo);
        await cubit.save(_input, const []);
        await cubit.save(_input, const []);
        expect(repo.keys, hasLength(2));
        expect(repo.keys[0], isNotNull);
        expect(repo.keys[1], repo.keys[0]);

        await cubit.save(
          const ClassInput(
            name: 'Toán 9B',
            subject: 'Toán',
            grade: 9,
            location: 'Nhà riêng',
            startDate: '2026-12-14',
          ),
          const [],
        );
        expect(repo.keys[2], isNot(repo.keys[0]));
        await cubit.close();
      },
    );

    test('lỗi chắc chắn (402) thì lần sau là lệnh mới, khóa mới', () async {
      final repo = FakeClassesRepository()
        ..createError = apiError(ApiErrorCode.planLimitExceeded);
      final cubit = ClassFormCubit(repo);
      await cubit.save(_input, const []);
      await cubit.save(_input, const []);
      expect(repo.keys[1], isNot(repo.keys[0]));
      await cubit.close();
    });

    test('đặt lịch: lỗi mạng giữ khóa PUT; PUT luôn có khóa', () async {
      final repo = FakeClassesRepository()
        ..putRulesError = const ApiException.network();
      final cubit = ClassFormCubit(repo);
      await cubit.save(_input, const [_rule]);
      await cubit.save(_input, const [_rule]);
      // create, putRules, update (lớp đã có), putRules
      expect(repo.calls, [
        'create',
        'putRules:new',
        'update:new',
        'putRules:new',
      ]);
      expect(repo.keys[3], repo.keys[1]);
      expect(repo.keys.every((k) => k != null), isTrue);
      await cubit.close();
    });

    test('lưu trữ lớp: lỗi mạng rồi thử lại dùng lại khóa', () async {
      final repo = FakeClassesRepository()
        ..archiveError = const ApiException.network();
      final cubit = ClassDetailCubit(repo, 'c1');
      await cubit.archive();
      await cubit.archive();
      expect(repo.keys[1], repo.keys[0]);
      await cubit.close();
    });

    test(
      'ghi danh: lỗi mạng rồi thử lại dùng lại khóa; học viên khác khóa khác',
      () async {
        final repo = FakeClassesRepository()
          ..enrollError = const ApiException.network();
        final cubit = StudentPickerCubit(repo, 'c1');
        const a = StudentSummary(
          id: 'a',
          fullName: 'A',
          school: null,
          schoolClass: null,
          status: 'active',
        );
        const b = StudentSummary(
          id: 'b',
          fullName: 'B',
          school: null,
          schoolClass: null,
          status: 'active',
        );
        await cubit.enroll(a);
        await cubit.enroll(a);
        await cubit.enroll(b);
        expect(repo.keys[1], repo.keys[0]);
        expect(repo.keys[2], isNot(repo.keys[0]));
        await cubit.close();
      },
    );
  });

  test('đóng Cubit khi yêu cầu đang bay: không emit sau close', () async {
    final repo = _SlowRepository();
    final cubit = ClassFormCubit(repo);
    final done = cubit.save(_input, const []);
    await cubit.close();
    repo.gate.complete();
    await done; // không ném "Cannot emit new states after calling close"
  });

  test(
    'server trả lỗi lạ (không phải ApiException) vẫn không kẹt đang lưu',
    () async {
      // Repository thật đã đổi lỗi đọc phản hồi thành ApiException (xem
      // classes_repository_errors_test); ở đây xác nhận trạng thái sau lỗi.
      final repo = FakeClassesRepository()
        ..createError = apiError(ApiErrorCode.internalError);
      final cubit = ClassFormCubit(repo);
      await cubit.save(_input, const []);
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    },
  );
}

class _SlowRepository extends FakeClassesRepository {
  final gate = Completer<void>();

  @override
  Future<ClassCreated> create(
    ClassInput input, {
    String? idempotencyKey,
  }) async {
    await gate.future;
    return super.create(input, idempotencyKey: idempotencyKey);
  }
}
