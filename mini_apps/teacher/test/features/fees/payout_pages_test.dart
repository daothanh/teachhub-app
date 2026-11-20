import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/features/classes/widgets/read_only_field.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/fees/fees_routes.dart';

import '../classes/pump.dart';
import 'fake_fee_repository.dart';
import 'finders.dart';

void main() {
  late FakeFeeRepository fees;
  setUp(() {
    fees = FakeFeeRepository();
    GetIt.I.registerSingleton<FeeRepository>(fees);
  });
  tearDown(GetIt.I.reset);

  Future<GoRouter> open(
    WidgetTester tester, {
    String initial = FeesRoutes.payoutAccounts,
    double scale = 1,
  }) async {
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        ...feesRoutes('teacher'),
      ],
      initial: initial,
      textScale: scale,
    );
    addTearDown(router.dispose);
    return router;
  }

  testWidgets('route công khai: mở thẳng danh sách (màn chốt kỳ đi tới đây)', (
    tester,
  ) async {
    final router = await open(tester, initial: '/');
    // US-7.3 AC5: bị chặn PAYOUT_ACCOUNT_MISSING thì push route này.
    router.push(FeesRoutes.payoutAccounts);
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản nhận tiền'), findsWidgets);
    expect(fees.calls, contains('list'));
  });

  testWidgets('danh sách: chỉ hiện số đã che, có tên ngân hàng', (
    tester,
  ) async {
    fees.accounts = [sampleAccount()];
    await open(tester);
    expect(find.textContaining('******6789'), findsOneWidget);
    expect(find.textContaining('Vietcombank'), findsWidgets);
  });

  testWidgets(
    'thêm: thiếu ngân hàng/số/tên báo lỗi tại trường, không gọi API',
    (tester) async {
      await open(tester, initial: FeesRoutes.payoutNew);
      await tapButton(tester, 'Gửi mã xác thực');
      expect(find.text('Chọn ngân hàng.'), findsOneWidget);
      expect(find.text('Không được để trống.'), findsNWidgets(2));
      expect(fees.calls, isNot(contains('otp')));
    },
  );

  testWidgets('thêm: chọn ngân hàng, nhập số và tên → OTP → tạo', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Thêm tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ReadOnlyField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vietcombank'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldOf('Số tài khoản'), '0123456789');
    await tester.enterText(fieldOf('Tên chủ tài khoản'), 'NGUYEN VAN A');
    await tapButton(tester, 'Gửi mã xác thực');
    expect(fees.calls, contains('otp'));
    await tester.enterText(fieldOf('Mã xác thực (6 số)'), '482913');
    await tester.pumpAndSettle();
    await tapButton(tester, 'Xác nhận và lưu');
    expect(fees.sentAccountNos.single, '0123456789');
    expect(fees.sentOtps.single, '482913');
    expect(find.textContaining('******6789'), findsOneWidget);
  });

  for (final path in [FeesRoutes.payoutAccounts, FeesRoutes.payoutNew]) {
    testWidgets('chữ 130%: $path không tràn', (tester) async {
      fees.accounts = [
        sampleAccount(),
        sampleAccount(id: 'a2', primary: false),
      ];
      await open(tester, initial: path, scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  }
}
