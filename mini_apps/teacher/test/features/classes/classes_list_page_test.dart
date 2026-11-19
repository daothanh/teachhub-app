import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_classes_repository.dart';
import 'pump.dart';

void main() {
  late FakeClassesRepository repo;
  setUp(() {
    repo = FakeClassesRepository();
    GetIt.I.registerSingleton<ClassesRepository>(repo);
  });
  tearDown(GetIt.I.reset);

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    final router = await pumpRoutes(
      tester,
      classesRoutes('teacher'),
      initial: ClassesRoutes.list,
      textScale: scale,
    );
    addTearDown(router.dispose);
  }

  testWidgets('mặc định chỉ lớp đang dạy; tab lưu trữ tải lớp lưu trữ', (
    tester,
  ) async {
    repo.active = [sampleClass(enrolled: 3)];
    repo.archived = [sampleClass(id: 'c2', name: 'Văn 7C')];
    await open(tester);

    expect(repo.calls, ['list:active:1']);
    expect(find.text('Toán 9A'), findsOneWidget);
    expect(find.text('3 học viên'), findsOneWidget);
    expect(find.text('Văn 7C'), findsNothing);

    await tester.tap(find.text('Đã lưu trữ'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'list:archived:1');
    expect(find.text('Văn 7C'), findsOneWidget);
    expect(find.text('Toán 9A'), findsNothing);
  });

  testWidgets('chưa có lớp: trạng thái trống kèm nút tạo lớp', (tester) async {
    await open(tester);
    expect(find.text('Chưa có lớp nào'), findsOneWidget);
    expect(find.text('Tạo lớp'), findsOneWidget);
  });

  testWidgets('mất mạng: báo lỗi, thử lại tải được', (tester) async {
    repo.listError = const ApiException.network();
    repo.active = [sampleClass()];
    await open(tester);
    expect(find.textContaining('Không có mạng'), findsOneWidget);

    repo.listError = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Toán 9A'), findsOneWidget);
  });

  testWidgets('chữ 130% không vỡ', (tester) async {
    repo.active = [sampleClass(name: 'Toán nâng cao khối chín buổi tối')];
    await open(tester, scale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tải trang tiếp lỗi: không gọi lại vô hạn, bấm Thử lại mới gọi', (
    tester,
  ) async {
    repo
      ..active = [sampleClass()]
      ..listTotal = 40
      ..listErrorPage = 2;
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(repo.calls.where((c) => c == 'list:active:2'), hasLength(1));
    // Dựng lại thêm vài khung hình vẫn không gọi lại.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.calls.where((c) => c == 'list:active:2'), hasLength(1));

    repo.listErrorPage = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c == 'list:active:2'), hasLength(2));
  });
}
