import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teacher/features/fees/data/fee_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/fake_classes_repository.dart';
import '../classes/pump.dart';
import 'finders.dart';

void main() {
  late FakeClassesRepository repo;
  setUp(() {
    repo = FakeClassesRepository();
    GetIt.I.registerSingleton<ClassesRepository>(repo);
  });
  tearDown(GetIt.I.reset);

  Future<void> open(
    WidgetTester tester, {
    String path = ClassesRoutes.create,
    Object? extra,
    double scale = 1,
  }) async {
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push<TeachClass>(path, extra: extra),
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
  }

  Future<void> fillClass(WidgetTester tester) async {
    await tester.enterText(fieldOf('Tên lớp'), 'Toán 9A');
    await tester.enterText(fieldOf('Môn'), 'Toán');
    await tester.enterText(fieldOf('Khối (1–12)'), '9');
    await tester.enterText(fieldOf('Địa điểm'), 'Nhà riêng');
    await reveal(tester, inputOf('Ngày bắt đầu'));
    await tester.tap(inputOf('Ngày bắt đầu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> enableFee(WidgetTester tester) async {
    await reveal(tester, find.text('Thu học phí'));
    await tester.tap(find.text('Thu học phí'));
    await tester.pumpAndSettle();
  }

  testWidgets('lớp mới: công tắc học phí tắt, lưu không gửi học phí', (
    tester,
  ) async {
    await open(tester);
    await fillClass(tester);
    expect(find.text('Cách tính'), findsNothing);
    await tapButton(tester, 'Lưu');
    expect(repo.calls, ['create']);
  });

  testWidgets(
    'bật học phí: 3 kiểu, tiền hiện 150.000 đ, mặc định tính cả hai loại vắng',
    (tester) async {
      await open(tester);
      await fillClass(tester);
      await enableFee(tester);
      for (final t in ['Theo buổi', 'Theo tháng', 'Trọn khóa']) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.enterText(fieldOf('Đơn giá mỗi buổi'), '150000');
      await tester.pumpAndSettle();
      expect(find.text('150.000 đ'), findsOneWidget);
      final excused = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Tính tiền buổi vắng có phép'),
      );
      final unexcused = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Tính tiền buổi vắng không phép'),
      );
      expect([excused.value, unexcused.value], [true, true]);

      // Tắt vắng không phép rồi lưu: tạo lớp, PATCH học phí đúng quy tắc.
      await tester.tap(find.text('Tính tiền buổi vắng không phép'));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Lưu');
      expect(repo.calls, ['create', 'update:new:fee']);
      final body = repo.patchBodies.last;
      expect(body['feeType'], 'per_session');
      expect(body['feeAmount'], 150000);
      expect(body['feeRules'], {
        'chargeExcused': true,
        'chargeUnexcused': false,
        'deductCancelled': false,
        'installments': 1,
      });
    },
  );

  testWidgets(
    'theo tháng có "trừ buổi hủy"; trọn khóa có số đợt, gửi đợt đã nhập',
    (tester) async {
      await open(tester);
      await fillClass(tester);
      await enableFee(tester);
      await tapText(tester, 'Theo tháng');
      expect(find.text('Trừ tiền buổi giáo viên hủy'), findsOneWidget);
      expect(find.text('Tính tiền buổi vắng có phép'), findsNothing);
      expect(find.text('Số đợt thu (1–36)'), findsNothing);

      await tapText(tester, 'Trọn khóa');
      expect(find.text('Số đợt thu (1–36)'), findsOneWidget);
      expect(find.text('Trừ tiền buổi giáo viên hủy'), findsNothing);
      await tester.enterText(fieldOf('Tổng học phí cả khóa'), '3600000');
      await tester.enterText(fieldOf('Số đợt thu (1–36)'), '6');
      await tapButton(tester, 'Lưu');
      final body = repo.patchBodies.last;
      expect(body['feeType'], 'course');
      expect(body['feeAmount'], 3600000);
      expect((body['feeRules'] as Map)['installments'], 6);
    },
  );

  testWidgets('thiếu số tiền: lỗi tại ô, chưa gọi API', (tester) async {
    await open(tester);
    await fillClass(tester);
    await enableFee(tester);
    await tapButton(tester, 'Lưu');
    // Ô tiền nằm phía trên nút Lưu: cuộn ngược tới khi lỗi được dựng.
    await tester.scrollUntilVisible(
      find.text('Nhập số tiền.'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nhập số tiền.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('số đợt 37: lỗi tại ô số đợt', (tester) async {
    await open(tester);
    await fillClass(tester);
    await enableFee(tester);
    await tapText(tester, 'Trọn khóa');
    await tester.enterText(fieldOf('Tổng học phí cả khóa'), '1000000');
    await tester.enterText(fieldOf('Số đợt thu (1–36)'), '37');
    await tapButton(tester, 'Lưu');
    expect(
      find.text('Số đợt từ 1 đến 36, chỉ dùng cho trọn khóa.'),
      findsOneWidget,
    );
    expect(repo.calls, isEmpty);
  });

  testWidgets('422 VALIDATION_FAILED ở feeType: hiện lỗi dưới ô kiểu học phí', (
    tester,
  ) async {
    await open(tester);
    await fillClass(tester);
    await enableFee(tester);
    await tapText(tester, 'Trọn khóa');
    await tester.enterText(fieldOf('Tổng học phí cả khóa'), '3600000');
    repo.updateError = validationError({
      'feeType': ['Trọn khóa cần ngày kết thúc và lịch học.'],
    });
    await tapButton(tester, 'Lưu');
    expect(
      find.text('Trọn khóa cần ngày kết thúc và lịch học.'),
      findsOneWidget,
    );
    // Không có banner lỗi chung.
    expect(find.text('Có lỗi xảy ra, vui lòng thử lại.'), findsNothing);
  });

  testWidgets('429: thông báo chung, không gọi lại', (tester) async {
    await open(tester);
    await fillClass(tester);
    await enableFee(tester);
    await tester.enterText(fieldOf('Đơn giá mỗi buổi'), '100000');
    repo.updateError = apiError(ApiErrorCode.rateLimited);
    await tapButton(tester, 'Lưu');
    await tester.pump(const Duration(seconds: 5));
    expect(
      find.text('Bạn thao tác hơi nhanh. Chờ một lúc rồi thử lại.'),
      findsOneWidget,
    );
    expect(repo.calls, ['create', 'update:new:fee']);
  });

  testWidgets('sửa lớp có học phí: điền sẵn kiểu, tiền, quy tắc', (
    tester,
  ) async {
    final c = sampleClass(
      feeType: FeeType.perSession,
      feeAmount: 150000,
      feeRules: const FeeRules(chargeExcused: false),
    );
    repo.current = c;
    await open(tester, path: ClassesRoutes.edit('c1'), extra: c);
    await reveal(tester, find.text('Thu học phí'));
    expect(find.text('150.000 đ'), findsOneWidget);
    final excused = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Tính tiền buổi vắng có phép'),
    );
    expect(excused.value, isFalse);
    // Không đổi học phí → PATCH không có khóa học phí.
    await tapButton(tester, 'Lưu');
    expect(repo.calls, ['update:c1']);
    expect(repo.patchBodies.single.containsKey('feeType'), isFalse);
  });

  testWidgets('chữ 200%: phần học phí không tràn', (tester) async {
    await open(tester, scale: 2);
    await fillClass(tester);
    await enableFee(tester);
    await tapText(tester, 'Trọn khóa');
    expect(tester.takeException(), isNull);
  });
}
