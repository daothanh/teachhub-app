import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teacher/features/classes/widgets/roster_tile.dart';
import 'package:teacher/features/fees/data/fee_models.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/fees/fees_routes.dart';
import 'package:teacher/features/fees/pages/fee_override_page.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/fake_classes_repository.dart';
import '../classes/pump.dart';
import 'fake_fee_repository.dart';
import 'finders.dart';

const _plain = RosterEntry(
  enrollmentId: 'e1',
  studentId: 's1',
  fullName: 'Nguyễn Văn An',
  studentStatus: 'active',
  joinedOn: '2026-12-14',
);

void main() {
  late FakeFeeRepository fees;
  setUp(() {
    fees = FakeFeeRepository();
    GetIt.I.registerSingleton<FeeRepository>(fees);
    GetIt.I.registerSingleton<ClassesRepository>(FakeClassesRepository());
  });
  tearDown(GetIt.I.reset);

  /// Trang gốc có một dòng danh sách lớp; chạm "Giá riêng cho học viên" mở form.
  Future<List<Object?>> open(
    WidgetTester tester,
    RosterEntry entry, {
    FeeType? type = FeeType.perSession,
    double scale = 1,
  }) async {
    final changed = <Object?>[];
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: ListView(
              children: [
                RosterTile(
                  classId: 'c1',
                  entry: entry,
                  feeType: type,
                  onChanged: () => changed.add(true),
                ),
              ],
            ),
          ),
        ),
        ...feesRoutes('teacher'),
      ],
      initial: '/',
      textScale: scale,
    );
    addTearDown(router.dispose);
    await tester.tap(find.text('Giá riêng cho học viên'));
    await tester.pumpAndSettle();
    return changed;
  }

  testWidgets('nhãn "Giá riêng" chỉ hiện khi feeOverride khác null', (
    tester,
  ) async {
    Future<void> pumpTile(RosterEntry e) async {
      final router = await pumpRoutes(tester, [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: RosterTile(classId: 'c1', entry: e, onChanged: () {}),
          ),
        ),
      ], initial: '/');
      addTearDown(router.dispose);
    }

    await pumpTile(_plain);
    expect(find.byType(AppTag), findsNothing);
    await pumpTile(
      RosterEntry(
        enrollmentId: 'e1',
        studentId: 's1',
        fullName: 'Nguyễn Văn An',
        studentStatus: 'active',
        joinedOn: '2026-12-14',
        feeOverride: const FeeOverride(feeAmount: 120000),
      ),
    );
    expect(find.widgetWithText(AppTag, 'Giá riêng'), findsOneWidget);
  });

  testWidgets(
    'lưu giá riêng, quy tắc vắng riêng và miễn giảm → PUT, đóng và báo danh sách tải lại',
    (tester) async {
      final changed = await open(tester, _plain);
      await tester.enterText(fieldOf('Giá riêng'), '120000');
      await tester.pumpAndSettle();
      expect(find.text('120.000 đ'), findsOneWidget);

      // Kiểu theo buổi: chỉ hiện quy tắc vắng.
      expect(find.text('Quy tắc vắng riêng'), findsOneWidget);
      expect(find.text('Số đợt riêng (1–36)'), findsNothing);
      await tester.tap(find.text('Không tính').first);
      await tester.pumpAndSettle();

      await tapText(tester, 'Thêm khoản miễn giảm');
      await tester.enterText(fieldOf('Mô tả'), 'Con thứ hai');
      await tester.enterText(fieldOf('Phần trăm (1–100)'), '10');
      await tapText(tester, 'Thêm khoản miễn giảm');
      await tester.enterText(fieldOf('Mô tả').last, 'Hỗ trợ');
      await tapText(tester, 'Theo số tiền', last: true);
      await tester.enterText(fieldOf('Số tiền'), '50000');
      await tapButton(tester, 'Lưu giá riêng');

      expect(fees.calls, ['put:e1']);
      final o = fees.overrides.single;
      expect(o.feeAmount, 120000);
      expect(o.chargeExcused, false);
      expect(o.chargeUnexcused, isNull);
      expect(o.discounts.map((d) => (d.kind, d.description, d.value)), [
        (FeeDiscountKind.percent, 'Con thứ hai', 10),
        (FeeDiscountKind.amount, 'Hỗ trợ', 50000),
      ]);
      expect(changed, [true]);
      expect(find.text('Giá riêng cho học viên'), findsOneWidget);
    },
  );

  testWidgets('tối đa 5 khoản: nút thêm biến mất ở khoản thứ 5', (
    tester,
  ) async {
    await open(tester, _plain);
    for (var i = 0; i < 5; i++) {
      await tapText(tester, 'Thêm khoản miễn giảm');
    }
    expect(find.text('Thêm khoản miễn giảm'), findsNothing);
  });

  testWidgets(
    'mở lại mức riêng có sẵn: điền sẵn, có nút Xóa giá riêng gửi {}',
    (tester) async {
      final entry = RosterEntry(
        enrollmentId: 'e1',
        studentId: 's1',
        fullName: 'Nguyễn Văn An',
        studentStatus: 'active',
        joinedOn: '2026-12-14',
        feeOverride: const FeeOverride(
          feeAmount: 120000,
          discounts: [
            FeeDiscount(
              kind: FeeDiscountKind.percent,
              description: 'Con thứ',
              value: 10,
            ),
          ],
        ),
      );
      final changed = await open(tester, entry);
      expect(find.text('120.000 đ'), findsOneWidget);
      expect(find.text('Con thứ'), findsOneWidget);
      await tapButton(tester, 'Xóa giá riêng');
      expect(fees.overrides.single.toJson(), isEmpty);
      expect(changed, [true]);
    },
  );

  testWidgets('chưa có mức riêng: không có nút Xóa giá riêng', (tester) async {
    await open(tester, _plain);
    expect(find.text('Xóa giá riêng'), findsNothing);
  });

  testWidgets(
    'kiểu theo tháng chỉ hiện "trừ buổi hủy"; trọn khóa chỉ hiện số đợt',
    (tester) async {
      await open(tester, _plain, type: FeeType.monthly);
      expect(find.text('Trừ tiền buổi giáo viên hủy'), findsOneWidget);
      expect(find.text('Tính tiền buổi vắng có phép'), findsNothing);
    },
  );

  testWidgets('trọn khóa: số đợt 40 bị chặn ở máy', (tester) async {
    await open(tester, _plain, type: FeeType.course);
    await tester.enterText(fieldOf('Số đợt riêng (1–36)'), '40');
    await tapButton(tester, 'Lưu giá riêng');
    expect(find.text('Số đợt từ 1 đến 36.'), findsOneWidget);
    expect(fees.calls, isEmpty);
  });

  testWidgets('422: lỗi tại ô giá riêng', (tester) async {
    await open(tester, _plain);
    await tester.enterText(fieldOf('Giá riêng'), '5');
    fees.putError = validation({
      'feeAmount': ['Giá phải lớn hơn 0.'],
    });
    await tapButton(tester, 'Lưu giá riêng');
    expect(find.text('Giá phải lớn hơn 0.'), findsOneWidget);
  });

  testWidgets('429: thông báo chung, form còn nguyên, không gọi lại', (
    tester,
  ) async {
    await open(tester, _plain);
    await tester.enterText(fieldOf('Giá riêng'), '5');
    fees.putError = apiErr(ApiErrorCode.rateLimited);
    await tapButton(tester, 'Lưu giá riêng');
    expect(
      find.text('Bạn thao tác hơi nhanh. Chờ một lúc rồi thử lại.'),
      findsOneWidget,
    );
    expect(fees.calls, ['put:e1']);
    expect(find.text('5 đ'), findsOneWidget);
  });

  testWidgets('chữ 200%: màn giá riêng có 5 khoản không tràn', (tester) async {
    await open(tester, _plain, scale: 2);
    for (var i = 0; i < 5; i++) {
      await tapText(tester, 'Thêm khoản miễn giảm');
    }
    expect(tester.takeException(), isNull);
  });

  test('FeeOverrideArgs mặc định hiện đủ quy tắc', () {
    expect(const FeeOverrideArgs().feeType, isNull);
    expect(
      FeesRoutes.feeOverride('c1', 'e1'),
      '/t/classes/c1/enrollments/e1/fee',
    );
  });
}
