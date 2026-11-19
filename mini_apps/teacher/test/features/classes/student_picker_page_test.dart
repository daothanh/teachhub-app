import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_classes_repository.dart';
import 'pump.dart';

const _an = StudentSummary(
  id: 's1',
  fullName: 'Nguyễn Văn An',
  school: 'THCS Nguyễn Du',
  schoolClass: '9A',
  status: 'active',
);

void main() {
  late FakeClassesRepository repo;
  setUp(() {
    repo = FakeClassesRepository()..students = [_an];
    GetIt.I.registerSingleton<ClassesRepository>(repo);
  });
  tearDown(GetIt.I.reset);

  Future<List<bool?>> open(WidgetTester tester, {double scale = 1}) async {
    final results = <bool?>[];
    final router = await pumpRoutes(tester, [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async => results.add(
              await context.push<bool>(ClassesRoutes.addStudent('c1')),
            ),
            child: const Text('mở'),
          ),
        ),
      ),
      ...classesRoutes('teacher'),
    ], initial: '/');
    addTearDown(router.dispose);
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    return results;
  }

  Future<void> type(WidgetTester tester, String q) async {
    await tester.enterText(find.byType(EditableText), q);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('gõ dưới 2 ký tự: nhắc, chưa gọi API', (tester) async {
    await open(tester);
    await type(tester, 'a');
    expect(find.text('Gõ ít nhất 2 ký tự để tìm.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('tìm không dấu rồi chọn hồ sơ: ghi danh, đóng với true', (
    tester,
  ) async {
    final results = await open(tester);
    await type(tester, 'nguyen');
    expect(repo.lastQuery, 'nguyen');
    expect(find.text('Nguyễn Văn An'), findsOneWidget);

    await tester.tap(find.text('Nguyễn Văn An'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'enroll:c1:s1');
    expect(results, [true]);
    expect(find.text('Đã thêm Nguyễn Văn An vào lớp.'), findsOneWidget);
  });

  testWidgets('đã có trong lớp (200): báo đã có, không tạo hồ sơ mới', (
    tester,
  ) async {
    repo.alreadyEnrolled = true;
    final results = await open(tester);
    await type(tester, 'nguyen');
    await tester.tap(find.text('Nguyễn Văn An'));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An đã có trong lớp.'), findsOneWidget);
    expect(results, [true]);
    expect(repo.calls.where((c) => c.startsWith('create')), isEmpty);
  });

  testWidgets('không có kết quả: gợi ý, không có nút tạo hồ sơ', (
    tester,
  ) async {
    repo.students = [];
    await open(tester);
    await type(tester, 'zz');
    expect(find.text('Không thấy học viên nào khớp.'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('402 hết hạn mức: báo lỗi, màn vẫn mở', (tester) async {
    repo.enrollError = apiError(ApiErrorCode.planLimitExceeded);
    final results = await open(tester);
    await type(tester, 'nguyen');
    await tester.tap(find.text('Nguyễn Văn An'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hết hạn mức'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('409 CONFLICT_STALE: lớp đã lưu trữ hoặc học viên đã nghỉ', (
    tester,
  ) async {
    repo.enrollError = apiError(ApiErrorCode.conflictStale);
    await open(tester);
    await type(tester, 'nguyen');
    await tester.tap(find.text('Nguyễn Văn An'));
    await tester.pumpAndSettle();
    expect(find.textContaining('học viên đã nghỉ'), findsOneWidget);
  });

  testWidgets('gõ liên tục chỉ gọi API một lần sau khi dừng gõ', (
    tester,
  ) async {
    await open(tester);
    for (final q in ['ng', 'ngu', 'nguy']) {
      await tester.enterText(find.byType(EditableText), q);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c.startsWith('search')), ['search:nguy']);
  });

  testWidgets('chữ 130% không vỡ (kết quả dài, lỗi)', (tester) async {
    repo.students = [
      const StudentSummary(
        id: 's9',
        fullName: 'Nguyễn Thị Hoàng Phương Anh Thư Khánh Linh',
        school: 'Trường THCS Nguyễn Văn Trỗi quận Hải Châu',
        schoolClass: '9A12',
        status: 'active',
      ),
    ];
    repo.enrollError = apiError(ApiErrorCode.conflictStale);
    await open(tester, scale: 1.3);
    await type(tester, 'nguyen');
    await tester.tap(find.textContaining('Nguyễn Thị Hoàng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('học viên đã nghỉ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
