import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/onboarding/data/onboarding_models.dart';
import 'package:teacher/features/onboarding/data/onboarding_repository.dart';
import 'package:teacher/features/onboarding/pages/onboarding_page.dart';
import 'package:teacher/features/students/data/student_models.dart';
import 'package:teacher/features/students/data/student_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../support/fakes.dart';
import 'fees/fake_fee_repository.dart';
import '../support/pump_app.dart';
import 'classes/fake_classes_repository.dart';

const _done = OnboardingStatus.done;

Finder _input(String label) => find.byWidgetPredicate(
  (w) => w is AppInput && w.label == label,
  skipOffstage: false,
);

Finder _field(String label) =>
    find.descendant(of: _input(label), matching: find.byType(EditableText));

Future<void> _reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  FakeOnboardingRepository onboarding,
  FakeClassesRepository classes, {
  double scale = 1,
}) async {
  await GetIt.I.reset();
  GetIt.I.registerSingleton<OnboardingRepository>(onboarding);
  GetIt.I.registerSingleton<ClassesRepository>(classes);
  GetIt.I.registerSingleton<FeeRepository>(FakeFeeRepository());
  GetIt.I.registerSingleton<StudentRepository>(
    FakeStudentRepository([const Student(id: 's1', fullName: 'Minh Anh')]),
  );
  await pumpApp(tester, const OnboardingPage(), textScale: scale);
}

Future<void> _fillClass(WidgetTester tester) async {
  await tester.enterText(_field('Tên lớp'), 'Toán 9A');
  await tester.enterText(_field('Môn'), 'Toán');
  await tester.enterText(_field('Khối (1–12)'), '9');
  await tester.enterText(_field('Địa điểm'), 'Nhà riêng');
  await _reveal(tester, _input('Ngày bắt đầu'));
  await tester.tap(_input('Ngày bắt đầu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  final btn = find.widgetWithText(AppButton, 'Lưu');
  await _reveal(tester, btn);
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

Future<void> _addRule(WidgetTester tester) async {
  final add = find.widgetWithText(AppButton, 'Thêm buổi');
  await _reveal(tester, add);
  await tester.tap(add);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(GetIt.I.reset);

  final atStep3 = onboardingOf({
    OnboardingStep.createClass: _done,
    OnboardingStep.addStudents: _done,
  });

  group('bước 1: form lớp có sẵn', () {
    testWidgets('lưu thật qua API lớp, ghi done, sang bước 2; không có lịch', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(onboardingOf({}));
      final classes = FakeClassesRepository();
      await _open(tester, onboarding, classes);

      expect(find.text('Bước 1/5'), findsOneWidget);
      expect(find.text('Để sau'), findsNothing);
      expect(find.text('Thêm buổi'), findsNothing); // lịch để bước 3
      await _fillClass(tester);
      await _save(tester);

      expect(classes.calls, ['create']);
      expect(onboarding.patches, [(OnboardingStep.createClass, _done)]);
      expect(find.text('Bước 2/5'), findsOneWidget);
    });

    testWidgets('thiếu trường: báo lỗi, không gọi API, không ghi bước', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(onboardingOf({}));
      final classes = FakeClassesRepository();
      await _open(tester, onboarding, classes);
      await _save(tester);

      expect(find.text('Không được để trống.'), findsWidgets);
      expect(classes.calls, isEmpty);
      expect(onboarding.patches, isEmpty);
    });

    testWidgets('ghi bước lỗi: thử lại chỉ ghi bước, không tạo lớp thứ hai', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(
        onboardingOf({}),
        patchError: const ApiException.network(),
      );
      final classes = FakeClassesRepository();
      await _open(tester, onboarding, classes);
      await _fillClass(tester);
      await _save(tester);

      expect(find.text('Đã lưu. Chưa ghi nhận được bước này.'), findsOneWidget);
      onboarding.patchError = null;
      // SnackBar lỗi ghi bước che nút ở cuối màn: gọi thẳng handler.
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Thử lại'))
          .onPressed!();
      await tester.pumpAndSettle();

      expect(classes.calls, ['create']);
      expect(onboarding.patches.last, (OnboardingStep.createClass, _done));
      expect(find.text('Bước 2/5'), findsOneWidget);
    });

    testWidgets('chữ 130%: không tràn', (tester) async {
      await _open(
        tester,
        FakeOnboardingRepository(onboardingOf({})),
        FakeClassesRepository(),
        scale: 1.3,
      );
      await _save(tester); // hiện đủ lỗi trường
      expect(tester.takeException(), isNull);
    });
  });

  group('bước 3: form quy tắc lặp có sẵn', () {
    testWidgets('lưu quy tắc cho lớp đã tạo, ghi done, sang bước 4', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(atStep3);
      final classes = FakeClassesRepository()..active = [sampleClass()];
      await _open(tester, onboarding, classes);

      expect(find.text('Bước 3/5'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
      await _addRule(tester);
      await _save(tester);

      expect(classes.lastRules, hasLength(1));
      expect(classes.calls, contains('putRules:c1'));
      expect(onboarding.patches, [(OnboardingStep.setSchedule, _done)]);
      expect(find.text('Bước 4/5'), findsOneWidget);
    });

    testWidgets('kill app ở bước 3, mở lại: đúng bước 3, quy tắc còn', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(atStep3);
      final classes = FakeClassesRepository()..active = [sampleClass()];
      await _open(tester, onboarding, classes);
      await _addRule(tester);
      // Ghi lịch thành công nhưng ghi bước lỗi (app bị kill ngay sau đó).
      onboarding.patchError = const ApiException.network();
      await _save(tester);
      expect(onboarding.patches.last.$2, _done);

      // Mở lại: server giữ quy tắc (bản giả không tự lưu, nên gán lại).
      classes.active = [sampleClass(rules: classes.lastRules!)];
      onboarding.patchError = null;
      await tester.pumpWidget(const SizedBox());
      await _open(tester, onboarding, classes);

      expect(find.text('Bước 3/5'), findsOneWidget);
      expect(find.text('Buổi 1'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
    });

    testWidgets('chưa có lớp: báo, không có form', (tester) async {
      await _open(
        tester,
        FakeOnboardingRepository(atStep3),
        FakeClassesRepository(),
      );
      expect(
        find.text('Chưa có lớp để đặt lịch. Hãy tạo lớp ở bước 1.'),
        findsOneWidget,
      );
      expect(find.text('Thêm buổi'), findsNothing);
    });

    testWidgets('chữ 130%: nhiều buổi và lỗi trùng không tràn', (tester) async {
      await _open(
        tester,
        FakeOnboardingRepository(atStep3),
        FakeClassesRepository()..active = [sampleClass()],
        scale: 1.3,
      );
      await _addRule(tester);
      await _addRule(tester);
      await _save(tester);
      expect(find.text('Có hai buổi cùng thứ và giờ bắt đầu.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
