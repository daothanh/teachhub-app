import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/features/onboarding/data/onboarding_draft.dart';
import 'package:teacher/features/onboarding/data/onboarding_models.dart';
import 'package:teacher/features/onboarding/data/onboarding_repository.dart';
import 'package:teacher/features/onboarding/pages/onboarding_page.dart';
import 'package:teacher/features/students/data/student_models.dart';
import 'package:teacher/features/students/data/student_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../support/fakes.dart';
import 'classes/fake_classes_repository.dart';
import 'fees/fake_fee_repository.dart';
import '../support/pump_app.dart';

const _done = OnboardingStatus.done;

Future<FakeOnboardingRepository> _open(
  WidgetTester tester,
  FakeOnboardingRepository repo, {
  StudentRepository? students,
  FakeFeeRepository? fees,
  FakeClassesRepository? classes,
}) async {
  GetIt.I.registerSingleton<OnboardingRepository>(repo);
  GetIt.I.registerSingleton<OnboardingDraftStore>(
    OnboardingDraftStore(InMemoryKeyValueStore()),
  );
  GetIt.I.registerSingleton<ClassesRepository>(
    classes ?? (FakeClassesRepository()..active = [sampleClass()]),
  );
  GetIt.I.registerSingleton<FeeRepository>(fees ?? FakeFeeRepository());
  GetIt.I.registerSingleton<StudentRepository>(
    students ??
        FakeStudentRepository([const Student(id: 's1', fullName: 'Minh Anh')]),
  );
  await pumpApp(tester, const OnboardingPage());
  return repo;
}

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('mở lần đầu: bước 1, không có "Để sau"', (tester) async {
    await _open(tester, FakeOnboardingRepository(onboardingOf({})));
    expect(find.text('Bước 1/5'), findsOneWidget);
    expect(find.text('Tạo lớp đầu tiên'), findsOneWidget);
    expect(find.text('Để sau'), findsNothing);
  });

  testWidgets('bước 1 đã xong: bước 2 nhúng form học viên', (tester) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
      ),
    );
    expect(find.text('Bước 2/5'), findsOneWidget);
    expect(find.textContaining('Họ và tên'), findsOneWidget);
    expect(find.text('Để sau'), findsOneWidget);
  });

  testWidgets('mở lại giữa chừng: vào đúng bước dở (bước 4)', (tester) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({
          OnboardingStep.createClass: _done,
          OnboardingStep.addStudents: _done,
          OnboardingStep.setSchedule: OnboardingStatus.skipped,
        }),
      ),
    );
    expect(find.text('Bước 4/5'), findsOneWidget);
    expect(find.text('Tài khoản nhận tiền'), findsOneWidget);
  });

  testWidgets(
    'bước 4: danh sách tài khoản thật; có tài khoản thì Tiếp tục ghi done',
    (tester) async {
      final fees = FakeFeeRepository()..accounts = [sampleAccount()];
      final repo = await _open(
        tester,
        FakeOnboardingRepository(
          onboardingOf({
            OnboardingStep.createClass: _done,
            OnboardingStep.addStudents: _done,
            OnboardingStep.setSchedule: OnboardingStatus.skipped,
          }),
        ),
        fees: fees,
      );
      expect(find.text('Vietcombank · ******6789'), findsOneWidget);
      expect(find.text('Tính năng sắp có.'), findsNothing);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(repo.patches.first, (
        OnboardingStep.payoutAccount,
        OnboardingStatus.done,
      ));
    },
  );

  testWidgets(
    'bước 4 chưa có tài khoản: chỉ có nút Thêm tài khoản, không có Tiếp tục',
    (tester) async {
      await _open(
        tester,
        FakeOnboardingRepository(
          onboardingOf({
            OnboardingStep.createClass: _done,
            OnboardingStep.addStudents: _done,
            OnboardingStep.setSchedule: OnboardingStatus.skipped,
          }),
        ),
      );
      expect(find.text('Thêm tài khoản'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsNothing);
    },
  );

  testWidgets('"Để sau" ở bước 2 gửi skipped và chuyển bước 3', (tester) async {
    final repo = await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
      ),
    );
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    expect(repo.patches, [
      (OnboardingStep.addStudents, OnboardingStatus.skipped),
    ]);
    expect(find.text('Bước 3/5'), findsOneWidget);
  });

  testWidgets('lưu học viên ở bước 2 đánh dấu bước xong', (tester) async {
    final repo = await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
      ),
    );
    await tester.enterText(find.byType(EditableText).first, 'Minh Anh');
    await tester.tap(find.text('Lưu học viên'));
    await tester.pumpAndSettle();

    expect(repo.patches, [(OnboardingStep.addStudents, _done)]);
    expect(find.text('Bước 3/5'), findsOneWidget);
  });

  testWidgets('xong hết 5 bước: màn hoàn tất', (tester) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({
          for (final s in OnboardingStep.values) s: OnboardingStatus.skipped,
          OnboardingStep.createClass: _done,
        }),
      ),
    );
    expect(find.text('Bạn đã xong phần làm quen'), findsOneWidget);
  });

  testWidgets('422 khi lưu bước: thông báo, vẫn ở bước hiện tại', (
    tester,
  ) async {
    final repo = FakeOnboardingRepository(
      onboardingOf({OnboardingStep.createClass: _done}),
      patchError: ApiException.fromResponse(422, {'code': 'VALIDATION_FAILED'}),
    );
    await _open(tester, repo);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    expect(find.text('Bước này chưa lưu được. Kiểm tra lại.'), findsOneWidget);
    expect(find.text('Bước 2/5'), findsOneWidget);
  });

  testWidgets('409 đang xử lý: thông báo thử lại', (tester) async {
    final repo = FakeOnboardingRepository(
      onboardingOf({OnboardingStep.createClass: _done}),
      patchError: ApiException.fromResponse(409, {
        'code': 'IDEMPOTENCY_IN_PROGRESS',
      }),
    );
    await _open(tester, repo);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(
      find.text('Yêu cầu đang xử lý. Thử lại sau giây lát.'),
      findsOneWidget,
    );
  });

  testWidgets('tải lỗi: có nút Thử lại và tải lại được', (tester) async {
    final repo = FakeOnboardingRepository(
      onboardingOf({}),
      getError: const ApiException.network(),
    );
    await _open(tester, repo);
    expect(find.text('Không tải được tiến độ. Thử lại.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('bước 3-5 placeholder chỉ có "Để sau", không có nút xong', (
    tester,
  ) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({
          OnboardingStep.createClass: _done,
          OnboardingStep.addStudents: _done,
        }),
      ),
    );
    expect(find.text('Bước 3/5'), findsOneWidget);
    expect(find.text('Xong bước này'), findsNothing);
    expect(find.text('Để sau'), findsOneWidget);
  });

  testWidgets(
    'PATCH lỗi sau khi lưu học viên: khóa form, Thử lại chỉ gọi PATCH',
    (tester) async {
      final repo = FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
        patchError: const ApiException.network(),
      );
      final students = FakeStudentRepository([
        const Student(id: 's1', fullName: 'Minh Anh'),
      ]);
      await _open(tester, repo, students: students);
      await tester.enterText(find.byType(EditableText).first, 'Minh Anh');
      await tester.tap(find.text('Lưu học viên'));
      await tester.pumpAndSettle();

      expect(find.text('Đã lưu. Chưa ghi nhận được bước này.'), findsOneWidget);
      expect(find.text('Bước 2/5'), findsOneWidget);

      repo.patchError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(students.calls, hasLength(1));
      expect(repo.patches, [
        (OnboardingStep.addStudents, _done),
        (OnboardingStep.addStudents, _done),
      ]);
      expect(find.text('Bước 3/5'), findsOneWidget);
    },
  );
}
