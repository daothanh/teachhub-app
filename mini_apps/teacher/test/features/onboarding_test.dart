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

/// "+ Thêm học sinh" rồi "Tiếp tục (1 học sinh)" ở bước 2.
Future<void> _addStudent(WidgetTester tester) async {
  final add = find.text('+ Thêm học sinh');
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  await tester.tap(add);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tiếp tục (1 học sinh)'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('mở lần đầu: bước 1, "Bỏ qua" không bấm được', (tester) async {
    await _open(tester, FakeOnboardingRepository(onboardingOf({})));
    expect(find.text('Bước 1/3'), findsOneWidget);
    expect(find.text('Tạo lớp đầu tiên'), findsOneWidget);
    expect(find.text('Thiết lập lớp học'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Bỏ qua'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('bước 1 đã xong: bước 2 nhúng form học viên', (tester) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
      ),
    );
    expect(find.text('Bước 2/3'), findsOneWidget);
    expect(find.textContaining('Họ tên học sinh'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
  });

  testWidgets('mở lại giữa chừng: vào đúng bước dở (bước 3)', (tester) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({
          OnboardingStep.createClass: _done,
          OnboardingStep.addStudents: OnboardingStatus.skipped,
        }),
      ),
    );
    expect(find.text('Bước 3/3'), findsOneWidget);
    expect(find.text('Lịch học hằng tuần'), findsOneWidget);
  });

  testWidgets('bước 2 chỉ nhập tay: không có "Thêm từ danh bạ" hàng loạt', (
    tester,
  ) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
      ),
    );
    expect(find.text('Thêm từ danh bạ'), findsNothing);
    expect(find.byTooltip('Chọn số từ danh bạ'), findsOneWidget);
  });

  testWidgets('"Bỏ qua" ở bước 2 gửi skipped và chuyển bước 3', (tester) async {
    final repo = await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
      ),
    );
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

    expect(repo.patches, [
      (OnboardingStep.addStudents, OnboardingStatus.skipped),
    ]);
    expect(find.text('Bước 3/3'), findsOneWidget);
  });

  testWidgets('lưu học viên ở bước 2 đánh dấu bước xong', (tester) async {
    final repo = await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({OnboardingStep.createClass: _done}),
      ),
    );
    await tester.enterText(find.byType(EditableText).first, 'Minh Anh');
    await _addStudent(tester);

    expect(repo.patches, [(OnboardingStep.addStudents, _done)]);
    expect(find.text('Bước 3/3'), findsOneWidget);
  });

  testWidgets('xong hết 3 bước: màn hoàn tất', (tester) async {
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
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

    expect(find.text('Bước này chưa lưu được. Kiểm tra lại.'), findsOneWidget);
    expect(find.text('Bước 2/3'), findsOneWidget);
  });

  testWidgets('409 đang xử lý: thông báo thử lại', (tester) async {
    final repo = FakeOnboardingRepository(
      onboardingOf({OnboardingStep.createClass: _done}),
      patchError: ApiException.fromResponse(409, {
        'code': 'IDEMPOTENCY_IN_PROGRESS',
      }),
    );
    await _open(tester, repo);
    await tester.tap(find.text('Bỏ qua'));
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

  testWidgets('bước 3: có tiêu đề bước và "Bỏ qua"', (tester) async {
    await _open(
      tester,
      FakeOnboardingRepository(
        onboardingOf({
          OnboardingStep.createClass: _done,
          OnboardingStep.addStudents: _done,
        }),
      ),
    );
    expect(find.text('Bước 3/3'), findsOneWidget);
    expect(find.text('Lịch học hằng tuần'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
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
      await _addStudent(tester);

      expect(find.text('Đã lưu. Chưa ghi nhận được bước này.'), findsOneWidget);
      expect(find.text('Bước 2/3'), findsOneWidget);

      repo.patchError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(students.calls, hasLength(1));
      expect(repo.patches, [
        (OnboardingStep.addStudents, _done),
        (OnboardingStep.addStudents, _done),
      ]);
      expect(find.text('Bước 3/3'), findsOneWidget);
    },
  );
}
