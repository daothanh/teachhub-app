import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
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
  FakeStudentRepository? students,
  double scale = 1,
  double keyboard = 0,
  KeyValueStore? kv,

  /// Lớp đã tạo ở bước 1 (bản nháp bền vững); null = bước 1 chưa làm/bỏ qua.
  String? classId,
}) async {
  await GetIt.I.reset();
  kv ??= InMemoryKeyValueStore();
  final store = OnboardingDraftStore(kv);
  if (classId != null) await store.update((d) => d.copyWith(classId: classId));
  GetIt.I.registerSingleton<OnboardingDraftStore>(store);
  GetIt.I.registerSingleton<OnboardingRepository>(onboarding);
  GetIt.I.registerSingleton<ClassesRepository>(classes);
  GetIt.I.registerSingleton<FeeRepository>(FakeFeeRepository());
  GetIt.I.registerSingleton<StudentRepository>(
    students ??
        FakeStudentRepository([const Student(id: 's1', fullName: 'Minh Anh')]),
  );
  await pumpApp(
    tester,
    const OnboardingPage(),
    textScale: scale,
    keyboard: keyboard,
  );
}

Future<void> _fillClass(WidgetTester tester) async {
  // Figma B07: tên lớp, chọn môn và khối từ danh sách, mức phí theo buổi.
  await _reveal(tester, _input('Tên lớp'));
  await tester.enterText(_field('Tên lớp'), 'Toán 9A');
  for (final (label, value) in [('Môn', 'Toán'), ('Khối', '9')]) {
    await _reveal(tester, _input(label));
    await tester.tap(_field(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }
  await _reveal(tester, _input('Mức phí mỗi buổi'));
  await tester.enterText(_field('Mức phí mỗi buổi'), '200000');
  await tester.pumpAndSettle();
}

/// Nút chính ở thanh đáy: "Tiếp tục" (bước 1) hoặc "Hoàn tất" (bước 3).
Future<void> _save(WidgetTester tester) async {
  final next = find.widgetWithText(AppButton, 'Tiếp tục');
  final btn = next.evaluate().isNotEmpty
      ? next
      : find.widgetWithText(AppButton, 'Hoàn tất');
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

/// Bước 3 có sẵn một hàng "T2 · 17:30 · 90 phút" (Figma B09).
Future<void> _addRule(WidgetTester tester) async {}

Future<void> _saveStudent(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, 'Minh Anh');
  final save = find.text('+ Thêm học sinh');
  await _reveal(tester, save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

/// Bấm "Tiếp tục (n học sinh)" để ghi bước 2 xong.
Future<void> _continueStudents(WidgetTester tester, [int n = 1]) async {
  await tester.tap(find.text('Tiếp tục ($n học sinh)'));
  await tester.pumpAndSettle();
}

/// Gọi thẳng handler: SnackBar lỗi ghi bước che nút ở cuối màn.
void _retry(WidgetTester tester) => tester
    .widget<AppButton>(find.widgetWithText(AppButton, 'Thử lại'))
    .onPressed!();

/// Kill app: gỡ cây widget; kho khóa [kv] và server (các fake) còn nguyên.
Future<void> _kill(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  tearDown(GetIt.I.reset);

  final atStep2 = onboardingOf({OnboardingStep.createClass: _done});
  final atStep3 = onboardingOf({
    OnboardingStep.createClass: _done,
    OnboardingStep.addStudents: _done,
  });

  group('bước 1: form lớp có sẵn', () {
    testWidgets(
      'lưu qua API lớp, ghi done, sang bước 2; không lịch, không học phí',
      (tester) async {
        final onboarding = FakeOnboardingRepository(onboardingOf({}));
        final classes = FakeClassesRepository();
        await _open(tester, onboarding, classes);

        expect(find.text('Bước 1/3'), findsOneWidget);
        // Bước 1 bắt buộc: "Bỏ qua" hiện nhưng không bấm được (Figma B07).
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Bỏ qua'))
              .onPressed,
          isNull,
        );
        expect(find.text('+ Thêm'), findsNothing); // lịch để bước 3
        expect(find.byType(Scaffold), findsOneWidget); // không Scaffold con
        await _fillClass(tester);
        await _save(tester);

        // Tạo lớp rồi ghi học phí theo buổi (POST chưa nhận học phí).
        expect(classes.calls, ['create', 'update:new:fee']);
        expect(onboarding.patches, [(OnboardingStep.createClass, _done)]);
        expect(find.text('Bước 2/3'), findsOneWidget);
      },
    );

    testWidgets('thiếu trường: báo lỗi, không gọi API, không ghi bước', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(onboardingOf({}));
      final classes = FakeClassesRepository();
      await _open(tester, onboarding, classes);
      // Thiếu trường: nút "Tiếp tục" bị khóa (Figma B07).
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Tiếp tục'))
            .onPressed,
        isNull,
      );
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
      _retry(tester);
      await tester.pumpAndSettle();

      expect(classes.calls.where((c) => c == 'create'), hasLength(1));
      expect(onboarding.patches.last, (OnboardingStep.createClass, _done));
      expect(find.text('Bước 2/3'), findsOneWidget);
    });

    testWidgets('kill app sau khi tạo lớp, chưa ghi done: mở lại không tạo lớp '
        'mới, chỉ ghi lại bước', (tester) async {
      final kv = InMemoryKeyValueStore();
      final onboarding = FakeOnboardingRepository(
        onboardingOf({}),
        patchError: const ApiException.network(),
      );
      final classes = FakeClassesRepository();
      await _open(tester, onboarding, classes, kv: kv);
      await _fillClass(tester);
      await _save(tester);
      expect(classes.calls.where((c) => c == 'create'), hasLength(1));

      await _kill(tester);
      onboarding.patchError = null;
      await _open(tester, onboarding, classes, kv: kv);

      expect(
        classes.calls.where((c) => c == 'create'),
        hasLength(1),
        reason: 'không tạo lớp thứ hai',
      );
      expect(onboarding.patches.last, (OnboardingStep.createClass, _done));
      expect(find.text('Bước 2/3'), findsOneWidget);
    });

    testWidgets(
      'kill app khi phản hồi tạo lớp bị mất: gửi lại dùng cùng khóa',
      (tester) async {
        final kv = InMemoryKeyValueStore();
        final onboarding = FakeOnboardingRepository(onboardingOf({}));
        final classes = FakeClassesRepository()
          ..createError = const ApiException.network();
        await _open(tester, onboarding, classes, kv: kv);
        await _fillClass(tester);
        await _save(tester);
        expect(onboarding.patches, isEmpty);

        await _kill(tester);
        classes.createError = null;
        await _open(tester, onboarding, classes, kv: kv);
        await _fillClass(tester);
        await _save(tester);

        // Khóa của hai lần tạo lớp (lần sau còn ghi học phí).
        expect(classes.keys.length, greaterThanOrEqualTo(2));
        expect(classes.keys[0], classes.keys[1]);
        expect(find.text('Bước 2/3'), findsOneWidget);
      },
    );

    testWidgets('chữ 130%, bàn phím mở: lỗi và nút Thử lại không tràn', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(
        onboardingOf({}),
        patchError: const ApiException.network(),
      );
      await _open(
        tester,
        onboarding,
        FakeClassesRepository(),
        scale: 1.3,
        keyboard: 300,
      );
      expect(tester.takeException(), isNull);
      await _fillClass(tester);
      await _save(tester);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('bước 2: học viên ghi danh vào lớp bước 1', () {
    testWidgets('lưu học viên rồi ghi danh đúng lớp đã lưu, mới ghi done', (
      tester,
    ) async {
      final onboarding = FakeOnboardingRepository(atStep2);
      final classes = FakeClassesRepository()
        ..active = [sampleClass(id: 'other'), sampleClass()];
      await _open(tester, onboarding, classes, classId: 'c1');
      await _saveStudent(tester);

      expect(classes.calls.first, 'enroll:c1:s1');
      expect(classes.calls, isNot(contains('list:active:1')));
      expect(onboarding.patches, isEmpty, reason: 'còn thêm được em khác');
      expect(find.text('Minh Anh'), findsOneWidget);
      await _continueStudents(tester);
      expect(onboarding.patches, [(OnboardingStep.addStudents, _done)]);
      expect(find.text('Bước 3/3'), findsOneWidget);
    });

    testWidgets('chưa có lớp (bỏ qua bước 1): chỉ tạo học viên, không ghi danh '
        'và không báo lỗi', (tester) async {
      final onboarding = FakeOnboardingRepository(atStep2);
      final classes = FakeClassesRepository()..active = [sampleClass()];
      await _open(tester, onboarding, classes);
      await _saveStudent(tester);
      await _continueStudents(tester);

      expect(classes.calls.where((c) => c.startsWith('enroll')), isEmpty);
      expect(onboarding.patches, [(OnboardingStep.addStudents, _done)]);
      expect(
        find.text('Chưa thêm được vào lớp', findRichText: true),
        findsNothing,
      );
      expect(find.text('Bước 3/3'), findsOneWidget);
    });

    testWidgets(
      'ghi danh lỗi mạng: thử lại cùng khóa, không tạo học viên hai',
      (tester) async {
        final onboarding = FakeOnboardingRepository(atStep2);
        final classes = FakeClassesRepository()
          ..enrollError = const ApiException.network();
        final students = FakeStudentRepository([
          const Student(id: 's1', fullName: 'Minh Anh'),
        ]);
        await _open(
          tester,
          onboarding,
          classes,
          students: students,
          classId: 'c1',
        );
        await _saveStudent(tester);

        expect(onboarding.patches, isEmpty);
        expect(find.text('Bước 2/3'), findsOneWidget);
        classes.enrollError = null;
        _retry(tester);
        await tester.pumpAndSettle();
        await _continueStudents(tester);

        expect(students.calls, hasLength(1));
        expect(classes.calls.where((c) => c == 'enroll:c1:s1'), hasLength(2));
        expect(classes.keys[0], classes.keys[1]);
        expect(onboarding.patches, [(OnboardingStep.addStudents, _done)]);
        expect(find.text('Bước 3/3'), findsOneWidget);
      },
    );

    testWidgets(
      'ghi bước lỗi khi bấm Tiếp tục: báo chưa ghi nhận bước (không phải '
      '"chưa ghi danh"), Thử lại thì sang bước 3',
      (tester) async {
        final onboarding = FakeOnboardingRepository(
          atStep2,
          patchError: const ApiException.network(),
        );
        await _open(tester, onboarding, FakeClassesRepository(), classId: 'c1');
        await _saveStudent(tester);
        await _continueStudents(tester);
        expect(
          find.text('Đã lưu. Chưa ghi nhận được bước này.'),
          findsOneWidget,
        );
        expect(find.textContaining('Chưa thêm được vào lớp'), findsNothing);

        onboarding.patchError = null;
        _retry(tester);
        await tester.pumpAndSettle();
        expect(find.textContaining('Chưa thêm được vào lớp'), findsNothing);
        expect(find.text('Bước 3/3'), findsOneWidget);
      },
    );

    testWidgets('kill app sau khi tạo học viên, chưa ghi done: mở lại ghi danh '
        'tiếp, không tạo học viên mới', (tester) async {
      final kv = InMemoryKeyValueStore();
      final onboarding = FakeOnboardingRepository(atStep2);
      final classes = FakeClassesRepository()
        ..enrollError = const ApiException.network();
      final students = FakeStudentRepository([
        const Student(id: 's1', fullName: 'Minh Anh'),
      ]);
      await _open(
        tester,
        onboarding,
        classes,
        students: students,
        kv: kv,
        classId: 'c1',
      );
      await _saveStudent(tester);
      expect(students.calls, hasLength(1));

      await _kill(tester);
      classes.enrollError = null;
      await _open(
        tester,
        onboarding,
        classes,
        students: students,
        kv: kv,
        classId: 'c1',
      );

      expect(
        students.calls,
        hasLength(1),
        reason: 'không tạo học viên thứ hai',
      );
      await _continueStudents(tester);
      expect(classes.calls.where((c) => c == 'enroll:c1:s1'), hasLength(2));
      expect(classes.keys[0], classes.keys[1]);
      expect(onboarding.patches, [(OnboardingStep.addStudents, _done)]);
      expect(find.text('Bước 3/3'), findsOneWidget);
    });

    testWidgets(
      'kill app khi phản hồi tạo học viên bị mất: gửi lại cùng khóa',
      (tester) async {
        final kv = InMemoryKeyValueStore();
        final onboarding = FakeOnboardingRepository(atStep2);
        final students = FakeStudentRepository([
          const ApiException.network(),
          const Student(id: 's1', fullName: 'Minh Anh'),
        ]);
        await _open(
          tester,
          onboarding,
          FakeClassesRepository(),
          students: students,
          kv: kv,
          classId: 'c1',
        );
        await _saveStudent(tester);

        await _kill(tester);
        await _open(
          tester,
          onboarding,
          FakeClassesRepository(),
          students: students,
          kv: kv,
          classId: 'c1',
        );
        await _saveStudent(tester);

        expect(students.calls, hasLength(2));
        expect(students.calls[0].key, students.calls[1].key);
      },
    );

    testWidgets('thêm 2 học sinh: danh sách và "Tiếp tục (2 học sinh)"; kill '
        'app vẫn còn danh sách', (tester) async {
      final kv = InMemoryKeyValueStore();
      final onboarding = FakeOnboardingRepository(atStep2);
      final classes = FakeClassesRepository();
      final students = FakeStudentRepository([
        const Student(id: 's1', fullName: 'Minh Anh'),
        const Student(id: 's2', fullName: 'Bảo Ngọc'),
      ]);
      await _open(
        tester,
        onboarding,
        classes,
        students: students,
        kv: kv,
        classId: 'c1',
      );
      await _saveStudent(tester);
      await _saveStudent(tester);
      expect(find.text('Minh Anh'), findsOneWidget);
      expect(find.text('Bảo Ngọc'), findsOneWidget);
      expect(classes.calls, containsAll(['enroll:c1:s1', 'enroll:c1:s2']));

      await _kill(tester);
      await _open(
        tester,
        onboarding,
        classes,
        students: students,
        kv: kv,
        classId: 'c1',
      );
      expect(find.text('Bảo Ngọc'), findsOneWidget);
      await _continueStudents(tester, 2);
      expect(onboarding.patches, [(OnboardingStep.addStudents, _done)]);
      expect(find.text('Bước 3/3'), findsOneWidget);
    });

    testWidgets('chữ 130%, bàn phím mở: nút Thử lại vẫn hiện', (tester) async {
      await _open(
        tester,
        FakeOnboardingRepository(atStep2),
        FakeClassesRepository()..enrollError = const ApiException.network(),
        scale: 1.3,
        keyboard: 300,
        classId: 'c1',
      );
      await _saveStudent(tester);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sang bước khác thì SnackBar "đã lưu" bị gỡ', (tester) async {
      final onboarding = FakeOnboardingRepository(onboardingOf({}));
      await _open(tester, onboarding, FakeClassesRepository());
      await _fillClass(tester);
      await _save(tester);

      expect(find.text('Bước 2/3'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('bước 3: form quy tắc lặp có sẵn', () {
    testWidgets('lưu quy tắc cho lớp đã lưu (get theo id), ghi done, xong '
        'onboarding', (tester) async {
      final onboarding = FakeOnboardingRepository(atStep3);
      final classes = FakeClassesRepository()
        ..active = [sampleClass(id: 'other')]
        ..current = sampleClass();
      await _open(tester, onboarding, classes, classId: 'c1');

      expect(find.text('Bước 3/3'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(classes.calls.first, 'get:c1');
      expect(classes.calls, isNot(contains('list:active:1')));
      await _addRule(tester);
      await _save(tester);

      expect(classes.lastRules, hasLength(1));
      expect(classes.calls, contains('putRules:c1'));
      expect(onboarding.patches, [(OnboardingStep.setSchedule, _done)]);
      expect(find.text('Bạn đã xong phần làm quen'), findsOneWidget);
    });

    testWidgets('kill app ở bước 3, mở lại: đúng bước 3, quy tắc còn', (
      tester,
    ) async {
      final kv = InMemoryKeyValueStore();
      final onboarding = FakeOnboardingRepository(atStep3);
      final classes = FakeClassesRepository()..current = sampleClass();
      await _open(tester, onboarding, classes, kv: kv, classId: 'c1');
      await _addRule(tester);
      // Ghi lịch thành công nhưng ghi bước lỗi (app bị kill ngay sau đó).
      onboarding.patchError = const ApiException.network();
      await _save(tester);
      expect(onboarding.patches.last.$2, _done);

      // Mở lại: server giữ quy tắc (bản giả không tự lưu, nên gán lại).
      classes.current = sampleClass(rules: classes.lastRules!);
      onboarding.patchError = null;
      await _kill(tester);
      await _open(tester, onboarding, classes, kv: kv, classId: 'c1');

      expect(find.text('Bước 3/3'), findsOneWidget);
      expect(find.text('T2'), findsOneWidget);
      expect(find.text('17:30'), findsOneWidget);
    });

    testWidgets('chưa có lớp nào: báo, không có form', (tester) async {
      await _open(
        tester,
        FakeOnboardingRepository(atStep3),
        FakeClassesRepository(),
      );
      expect(
        find.text('Chưa có lớp để đặt lịch. Hãy tạo lớp ở bước 1.'),
        findsOneWidget,
      );
      expect(find.text('+ Thêm'), findsNothing);
    });

    testWidgets('chưa lưu lớp nhưng có lớp: cho chọn, rồi tải đủ trường', (
      tester,
    ) async {
      final classes = FakeClassesRepository()
        ..active = [sampleClass(id: 'a', name: 'Lý 8B'), sampleClass()]
        ..current = sampleClass(id: 'a', name: 'Lý 8B');
      await _open(tester, FakeOnboardingRepository(atStep3), classes);

      expect(
        find.text('Bạn có nhiều lớp. Chọn lớp cần đặt lịch.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Lý 8B'));
      await tester.pumpAndSettle();
      expect(classes.calls, contains('get:a'));
      expect(find.text('+ Thêm'), findsOneWidget);
    });

    testWidgets('chữ 130%, bàn phím mở: nhiều buổi và lỗi trùng không tràn', (
      tester,
    ) async {
      await _open(
        tester,
        FakeOnboardingRepository(atStep3),
        FakeClassesRepository()..current = sampleClass(),
        scale: 1.3,
        keyboard: 300,
        classId: 'c1',
      );
      // "+ Thêm" chép giờ của hàng cuối, chọn cùng thứ T2 → chồng giờ.
      await tester.tap(find.text('+ Thêm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thứ').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('T2').last);
      await tester.pumpAndSettle();
      expect(find.text('Trùng giờ với buổi T2 17:30'), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Hoàn tất'))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
