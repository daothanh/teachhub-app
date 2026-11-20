import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/cubit/class_form_cubit.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/fees/data/fee_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/fake_classes_repository.dart';

const _base = ClassInput(
  name: 'Toán 9A',
  subject: 'Toán',
  grade: 9,
  location: 'Nhà riêng',
  startDate: '2026-12-14',
);
const _rule = ScheduleRule(weekday: 2, startTime: '18:00', durationMin: 90);

ClassInput _withFee({
  FeeType type = FeeType.perSession,
  int? amount = 150000,
  FeeRules rules = const FeeRules(),
}) => ClassInput(
  name: _base.name,
  subject: _base.subject,
  grade: _base.grade,
  location: _base.location,
  startDate: _base.startDate,
  feeType: type,
  feeAmount: amount,
  feeRules: rules,
);

void main() {
  test(
    'tạo lớp có học phí: POST không có học phí, rồi PATCH học phí sau lịch',
    () async {
      final repo = FakeClassesRepository();
      final cubit = ClassFormCubit(repo);
      await cubit.save(_withFee(), const [_rule]);

      // Học phí đặt cuối để `course` thấy quy tắc lịch đã lưu.
      expect(repo.calls, ['create', 'putRules:new', 'update:new:fee']);
      final body = repo.patchBodies.single;
      expect(body['feeType'], 'per_session');
      expect(body['feeAmount'], 150000);
      expect((body['feeRules'] as Map)['installments'], 1);
      expect(cubit.state.saved!.feeAmount, 150000);
      await cubit.close();
    },
  );

  test('tạo lớp không học phí: không PATCH', () async {
    final repo = FakeClassesRepository();
    final cubit = ClassFormCubit(repo);
    await cubit.save(_base, const []);
    expect(repo.calls, ['create']);
    expect(cubit.state.saved, isNotNull);
    await cubit.close();
  });

  test('sửa lớp, học phí không đổi: PATCH không có khóa học phí', () async {
    final c = sampleClass(
      feeType: FeeType.perSession,
      feeAmount: 150000,
      feeRules: const FeeRules(),
    );
    final repo = FakeClassesRepository()..current = c;
    final cubit = ClassFormCubit(repo, initial: c);
    await cubit.save(ClassInput.from(c), const []);
    expect(repo.calls, ['update:c1']);
    expect(repo.patchBodies.single.containsKey('feeType'), isFalse);
    await cubit.close();
  });

  test('sửa lớp đổi giá: PATCH có học phí', () async {
    final c = sampleClass(
      feeType: FeeType.perSession,
      feeAmount: 150000,
      feeRules: const FeeRules(),
    );
    final repo = FakeClassesRepository()..current = c;
    final cubit = ClassFormCubit(repo, initial: c);
    await cubit.save(_withFee(amount: 200000), const []);
    expect(repo.calls, ['update:c1', 'update:c1:fee']);
    expect(repo.patchBodies.last['feeAmount'], 200000);
    await cubit.close();
  });

  test('tắt học phí của lớp đã có: gửi feeType và feeAmount null', () async {
    final c = sampleClass(
      feeType: FeeType.monthly,
      feeAmount: 800000,
      feeRules: const FeeRules(),
    );
    final repo = FakeClassesRepository()..current = c;
    final cubit = ClassFormCubit(repo, initial: c);
    await cubit.save(_base, const []);
    expect(repo.patchBodies.last['feeType'], isNull);
    expect(repo.patchBodies.last['feeAmount'], isNull);
    expect(repo.patchBodies.last.containsKey('feeType'), isTrue);
    await cubit.close();
  });

  test('thiếu số tiền: chặn ở máy, chưa gọi API', () async {
    final repo = FakeClassesRepository();
    final cubit = ClassFormCubit(repo);
    await cubit.save(_withFee(amount: null), const []);
    expect(
      cubit.state.clientErrors['feeAmount'],
      ClassFieldError.feeAmountRequired,
    );
    expect(repo.calls, isEmpty);
    await cubit.close();
  });

  test(
    '422 VALIDATION_FAILED ở feeType: lỗi tại trường, lớp đã tạo giữ lại',
    () async {
      final repo = FakeClassesRepository();
      final cubit = ClassFormCubit(repo);
      // Lỗi chỉ đến ở lệnh PATCH học phí (sau khi tạo lớp).
      repo.updateError = validationError({
        'feeType': ['Trọn khóa cần ngày kết thúc và lịch học.'],
      });
      await cubit.save(_withFee(type: FeeType.course), const []);
      expect(cubit.state.serverErrors['feeType'], isNotEmpty);
      expect(cubit.state.error, isNull);
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.initial!.id, 'new');
      expect(cubit.state.saved, isNull);
      await cubit.close();
    },
  );

  test('feeRules.installments từ server gộp vào feeRules', () async {
    final repo = FakeClassesRepository();
    final cubit = ClassFormCubit(repo);
    repo.updateError = validationError({
      'feeRules.installments': ['Chỉ trọn khóa.'],
    });
    await cubit.save(_withFee(type: FeeType.course), const []);
    expect(cubit.state.serverErrors['feeRules'], ['Chỉ trọn khóa.']);
    expect(cubit.state.error, isNull);
    await cubit.close();
  });

  test('429 RATE_LIMITED: báo lỗi, không tự thử lại', () async {
    final repo = FakeClassesRepository();
    final cubit = ClassFormCubit(repo);
    repo.updateError = apiError(ApiErrorCode.rateLimited);
    await cubit.save(_withFee(), const []);
    expect(cubit.state.error!.code, ApiErrorCode.rateLimited);
    expect(cubit.state.saving, isFalse);
    expect(repo.calls, ['create', 'update:new:fee']);
    await cubit.close();
  });
}
