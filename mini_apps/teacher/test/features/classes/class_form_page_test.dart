import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_classes_repository.dart';
import 'pump.dart';

Finder _input(String label) => find.byWidgetPredicate(
  (w) => w is AppInput && w.label == label,
  skipOffstage: false,
);

Finder _field(String label) =>
    find.descendant(of: _input(label), matching: find.byType(EditableText));

/// Danh sách dựng lười: cuộn tới khi widget được dựng rồi mới thao tác.
Future<void> _reveal(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  late FakeClassesRepository repo;
  setUp(() {
    repo = FakeClassesRepository();
    GetIt.I.registerSingleton<ClassesRepository>(repo);
  });
  tearDown(GetIt.I.reset);

  // Trang gốc đẩy form lên để kiểm kết quả đóng form.
  Future<List<Object?>> open(
    WidgetTester tester, {
    String path = ClassesRoutes.create,
    Object? extra,
    double scale = 1,
  }) async {
    final results = <Object?>[];
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await context.push<TeachClass>(path, extra: extra),
              ),
              child: const Text('mở'),
            ),
          ),
        ),
        ...classesRoutes('teacher'),
      ],
      initial: '/',
      textScale: scale,
    );
    addTearDown(router.dispose);
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    return results;
  }

  Future<void> fillBasics(WidgetTester tester) async {
    await tester.enterText(_field('Tên lớp'), 'Toán 9A');
    await tester.enterText(_field('Môn'), 'Toán');
    await tester.enterText(_field('Khối (1–12)'), '9');
  }

  Future<void> pickToday(WidgetTester tester, String label) async {
    await _reveal(tester, _input(label));
    await tester.tap(_input(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final btn = find.widgetWithText(AppButton, 'Lưu');
    await _reveal(tester, btn);
    await tester.tap(btn);
    await tester.pumpAndSettle();
  }

  testWidgets('lớp tại chỗ thiếu địa điểm: lỗi tại trường, chưa gọi API', (
    tester,
  ) async {
    await open(tester);
    await fillBasics(tester);
    await pickToday(tester, 'Ngày bắt đầu');
    await save(tester);

    expect(find.text('Không được để trống.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('lớp trực tuyến ẩn ô địa điểm và không gửi địa điểm', (
    tester,
  ) async {
    final results = await open(tester);
    await fillBasics(tester);
    await tester.tap(find.text('Trực tuyến'));
    await tester.pumpAndSettle();
    expect(find.text('Địa điểm'), findsNothing);
    await pickToday(tester, 'Ngày bắt đầu');
    await save(tester);

    expect(repo.calls, ['create']);
    expect(repo.lastInput!.toJson()['location'], isNull);
    expect(repo.lastInput!.mode, ClassMode.online);
    expect(results.single, isA<TeachClass>());
  });

  testWidgets(
    'sửa lớp có ngày kết thúc trước ngày bắt đầu: báo lỗi ở trường kết thúc',
    (tester) async {
      final c = TeachClass(
        id: 'c1',
        name: 'Toán 9A',
        subject: 'Toán',
        grade: 9,
        mode: ClassMode.online,
        location: null,
        capacity: null,
        startDate: '2026-12-14',
        endDate: '2026-12-01',
        status: ClassStatus.active,
        enrolledCount: 0,
        scheduleRules: const [],
        createdAt: '2026-12-01T00:00:00.000Z',
      );
      await open(tester, path: ClassesRoutes.edit('c1'), extra: c);
      await save(tester);

      expect(
        find.text('Ngày kết thúc không được trước ngày bắt đầu.'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
    },
  );

  testWidgets('422 theo trường từ server hiện đúng ô', (tester) async {
    repo.createError = validationError({
      'endDate': ['Ngày kết thúc không được trước ngày bắt đầu.'],
      'location': ['Vui lòng nhập địa điểm cho lớp học tại chỗ.'],
    });
    await open(tester);
    await fillBasics(tester);
    await tester.enterText(_field('Địa điểm'), 'Nhà riêng');
    await pickToday(tester, 'Ngày bắt đầu');
    await save(tester);

    expect(repo.calls, ['create']);
    expect(
      find.text('Ngày kết thúc không được trước ngày bắt đầu.'),
      findsOneWidget,
    );
    expect(
      find.text('Vui lòng nhập địa điểm cho lớp học tại chỗ.'),
      findsOneWidget,
    );
  });

  testWidgets('402 PLAN_LIMIT_EXCEEDED hiện thông báo hết hạn mức', (
    tester,
  ) async {
    repo.createError = apiError(ApiErrorCode.planLimitExceeded);
    await open(tester);
    await fillBasics(tester);
    await tester.enterText(_field('Địa điểm'), 'Nhà riêng');
    await pickToday(tester, 'Ngày bắt đầu');
    await save(tester);

    expect(find.textContaining('hết hạn mức'), findsOneWidget);
  });

  testWidgets('thêm T3 + T5 rồi lưu: tạo lớp, đặt quy tắc, đóng form', (
    tester,
  ) async {
    final results = await open(tester);
    await fillBasics(tester);
    await tester.enterText(_field('Địa điểm'), 'Nhà riêng');
    await pickToday(tester, 'Ngày bắt đầu');

    for (final day in ['T3', 'T5']) {
      final add = find.widgetWithText(AppButton, 'Thêm buổi');
      await _reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.text(day).last);
      await tester.pumpAndSettle();
    }
    await save(tester);

    expect(repo.calls, ['create', 'putRules:new']);
    expect(
      [
        for (final r in repo.lastRules!)
          (r.weekday, r.startTime, r.durationMin),
      ],
      [(2, '18:00', 90), (4, '18:00', 90)],
    );
    expect(results.single, isA<TeachClass>());
  });

  testWidgets('hai buổi cùng thứ và giờ: lỗi quy tắc, không gọi API', (
    tester,
  ) async {
    await open(tester);
    await fillBasics(tester);
    await tester.enterText(_field('Địa điểm'), 'Nhà riêng');
    await pickToday(tester, 'Ngày bắt đầu');
    for (var i = 0; i < 2; i++) {
      final add = find.widgetWithText(AppButton, 'Thêm buổi');
      await _reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
    }
    await save(tester);

    expect(find.text('Có hai buổi cùng thứ và giờ bắt đầu.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('đặt lịch lỗi sau khi tạo: bấm Lưu lại không tạo lớp thứ hai', (
    tester,
  ) async {
    repo.putRulesError = validationError({
      'rules': ['Quy tắc lặp không hợp lệ.'],
    });
    await open(tester);
    await fillBasics(tester);
    await tester.enterText(_field('Địa điểm'), 'Nhà riêng');
    await pickToday(tester, 'Ngày bắt đầu');
    final add = find.widgetWithText(AppButton, 'Thêm buổi');
    await _reveal(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await save(tester);
    expect(repo.calls, ['create', 'putRules:new']);
    expect(find.text('Quy tắc lặp không hợp lệ.'), findsOneWidget);

    repo.putRulesError = null;
    await save(tester);
    expect(repo.calls, [
      'create',
      'putRules:new',
      'update:new',
      'putRules:new',
    ]);
  });

  testWidgets('chữ 130%: form dài cuộn được, không tràn', (tester) async {
    await open(tester, scale: 1.3);
    final add = find.widgetWithText(AppButton, 'Thêm buổi');
    await _reveal(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _reveal(tester, find.widgetWithText(AppButton, 'Lưu'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sửa lớp chỉ truyền classId: tải lớp rồi điền form', (
    tester,
  ) async {
    repo.current = sampleClass(name: 'Lý 8B');
    await open(tester, path: ClassesRoutes.edit('c1'));
    expect(repo.calls, ['get:c1']);
    expect(find.text('Lý 8B'), findsOneWidget);
  });
}
