import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/plan/data/plan_models.dart';
import 'package:teacher/features/plan/data/purchase_service.dart';
import 'package:teacher/features/plan/pages/plan_page.dart';
import 'package:teacher/features/plan/plan_routes.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/fake_classes_repository.dart' show apiError;
import '../classes/pump.dart';
import 'fake_plan.dart';

void main() {
  late FakePlanRepository repo;
  late FakePurchaseService purchase;
  setUp(() {
    repo = FakePlanRepository();
    purchase = FakePurchaseService();
  });

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(
          path: PlanRoutes.plan,
          builder: (_, _) => PlanPage(repository: repo, purchase: purchase),
        ),
      ],
      initial: PlanRoutes.plan,
      textScale: scale,
    );
    addTearDown(router.dispose);
  }

  testWidgets('Free chưa dùng thử: mức dùng, tính năng khóa, ba nút', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Gói Miễn phí'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('20/20'), findsOneWidget);
    expect(find.text('Mẫu 02'), findsOneWidget);
    expect(find.text('Pro'), findsNWidgets(3));
    // Khóa lạ và khóa không có trong phản hồi (reports.export) không hiện.
    expect(find.text('Xuất báo cáo'), findsNothing);
    expect(find.text('Dùng thử 14 ngày'), findsOneWidget);
    expect(find.text('Mua Pro'), findsOneWidget);
    // R6: không có lựa chọn chuyển khoản hay thanh toán ngoài store.
    expect(find.textContaining('huyển khoản'), findsNothing);
    expect(find.textContaining('trên web'), findsNothing);
  });

  testWidgets('giá chỉ hiện khi store trả giá', (tester) async {
    purchase.price = '250.000 ₫';
    await open(tester);
    expect(find.text('Mua Pro · 250.000 ₫'), findsOneWidget);
  });

  testWidgets('bấm dùng thử: sang Pro, nút dùng thử biến mất', (tester) async {
    await open(tester);
    await tester.tap(find.text('Dùng thử 14 ngày'));
    await tester.pumpAndSettle();
    expect(repo.trialKeys, hasLength(1));
    expect(find.text('Gói Pro'), findsOneWidget);
    expect(find.text('Đang dùng thử Pro'), findsOneWidget);
    expect(find.text('Còn 14 ngày'), findsOneWidget);
    expect(find.text('Hết hạn ngày 05/12/2026'), findsOneWidget);
    expect(find.text('2 · không giới hạn'), findsOneWidget);
    expect(find.text('Dùng thử 14 ngày'), findsNothing);
    expect(
      find.textContaining('Đã bật Pro dùng thử · còn 14 ngày'),
      findsOneWidget,
    );
    expect(find.text('Mẫu 02'), findsOneWidget);
    expect(find.text('Đã mở'), findsNWidgets(3));
  });

  testWidgets('đã dùng thử: không có nút, có giải thích', (tester) async {
    repo.current = samplePlan(
      status: SubscriptionStatus.expired,
      trialAvailable: false,
      readOnlyClasses: 1,
      readOnlyStudents: 4,
    );
    await open(tester);
    expect(find.text('Dùng thử 14 ngày'), findsNothing);
    expect(
      find.textContaining('Mỗi tài khoản chỉ dùng thử một lần'),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 lớp và 4 học viên đang ở chế độ chỉ đọc'),
      findsOneWidget,
    );
    expect(find.text('Mua Pro'), findsOneWidget);
  });

  testWidgets('422 khi bấm dùng thử: báo lỗi và ẩn nút', (tester) async {
    await open(tester);
    repo.current = samplePlan(trialAvailable: false);
    repo.trialError = apiError(ApiErrorCode.trialAlreadyUsed);
    await tester.tap(find.text('Dùng thử 14 ngày'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã dùng thử Pro rồi.'), findsOneWidget);
    expect(find.text('Dùng thử 14 ngày'), findsNothing);
  });

  testWidgets('Pro trả phí: không có nút mua hay dùng thử', (tester) async {
    repo.current = samplePlan(
      isPro: true,
      status: SubscriptionStatus.active,
      daysLeft: 200,
      end: '2027-06-01T00:00:00+07:00',
      trialAvailable: false,
      maxClasses: null,
      maxStudents: null,
      pro: true,
    );
    await open(tester);
    expect(find.text('Pro đang hoạt động'), findsOneWidget);
    expect(find.text('Mua Pro'), findsNothing);
    expect(find.textContaining('dùng thử một lần'), findsNothing);
  });

  testWidgets('Mua Pro chưa có sản phẩm: báo, không treo', (tester) async {
    purchase.outcome = PurchaseOutcome.unavailable;
    await open(tester);
    await tester.tap(find.text('Mua Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Mua trong ứng dụng chưa sẵn sàng.'), findsOneWidget);
  });

  testWidgets('ngoại tuyến khi tải: báo lỗi, Thử lại tải được', (tester) async {
    repo.usageError = const ApiException.network();
    await open(tester);
    expect(find.text('Thử lại'), findsOneWidget);
    repo.usageError = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Gói Miễn phí'), findsOneWidget);
  });

  testWidgets('chữ 130%: không tràn', (tester) async {
    repo.current = samplePlan(readOnlyClasses: 2, readOnlyStudents: 9);
    await open(tester, scale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Mua Pro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
