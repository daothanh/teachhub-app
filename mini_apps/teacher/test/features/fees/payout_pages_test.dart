import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/features/classes/widgets/read_only_field.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/fees/fees_routes.dart';

import 'package:teachhub_shared/teachhub_shared.dart';

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

  Future<void> deleteFirst(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();
  }

  testWidgets('S3: xóa tài khoản duy nhất có cảnh báo chặn chốt kỳ', (
    tester,
  ) async {
    fees.accounts = [sampleAccount()];
    await open(tester);
    await deleteFirst(tester);
    expect(find.textContaining('tài khoản nhận tiền duy nhất'), findsOneWidget);
  });

  testWidgets('S3: còn nhiều tài khoản thì chỉ hiện câu xóa thường', (
    tester,
  ) async {
    fees.accounts = [sampleAccount(), sampleAccount(id: 'a2', primary: false)];
    await open(tester);
    await deleteFirst(tester);
    expect(find.textContaining('duy nhất'), findsNothing);
    expect(find.textContaining('gỡ khỏi danh sách'), findsOneWidget);
  });

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  Future<void> typeOtp(WidgetTester tester, String code) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(EditableText),
      ),
      code,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('P1: đặt tài khoản phụ làm chính → gửi mã, hỏi OTP, gửi kèm', (
    tester,
  ) async {
    fees.accounts = [sampleAccount(), sampleAccount(id: 'a2', primary: false)];
    await open(tester);
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt làm chính'));
    await tester.pumpAndSettle();
    expect(fees.calls, contains('otp'));
    expect(find.text('Xác thực để tiếp tục'), findsOneWidget);
    // Chưa đủ 6 số thì chưa xác nhận được.
    await typeOtp(tester, '123');
    await tester.tap(inDialog('Xác nhận'));
    await tester.pumpAndSettle();
    expect(fees.calls.where((c) => c.startsWith('update')), isEmpty);
    await typeOtp(tester, '123456');
    await tester.tap(inDialog('Xác nhận'));
    await tester.pumpAndSettle();
    expect(fees.calls, contains('update:a2:primary'));
    expect(fees.sentOtps.last, '123456');
  });

  testWidgets('P1: hủy hộp OTP thì không đặt chính', (tester) async {
    fees.accounts = [sampleAccount(), sampleAccount(id: 'a2', primary: false)];
    await open(tester);
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt làm chính'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('Hủy'));
    await tester.pumpAndSettle();
    expect(fees.calls.where((c) => c.startsWith('update')), isEmpty);
  });

  testWidgets('P1: không gửi được mã → báo lỗi, không hỏi OTP', (tester) async {
    fees.accounts = [sampleAccount(), sampleAccount(id: 'a2', primary: false)];
    fees.otpError = apiErr(ApiErrorCode.rateLimited);
    await open(tester);
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt làm chính'));
    await tester.pumpAndSettle();
    expect(find.text('Xác thực để tiếp tục'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('P1: xóa tài khoản chính khi còn khác → OTP trong body', (
    tester,
  ) async {
    fees.accounts = [sampleAccount(), sampleAccount(id: 'a2', primary: false)];
    await open(tester);
    await deleteFirst(tester);
    await tester.tap(inDialog('Xóa'));
    await tester.pumpAndSettle();
    await typeOtp(tester, '654321');
    await tester.tap(inDialog('Xác nhận'));
    await tester.pumpAndSettle();
    expect(fees.calls, contains('delete:a1'));
    expect(fees.sentOtps.last, '654321');
  });

  testWidgets('P1: xóa tài khoản phụ hoặc chính duy nhất không cần OTP', (
    tester,
  ) async {
    fees.accounts = [sampleAccount()];
    await open(tester);
    await deleteFirst(tester);
    await tester.tap(inDialog('Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Xác thực để tiếp tục'), findsNothing);
    expect(fees.calls, contains('delete:a1'));
    expect(fees.calls, isNot(contains('otp')));
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
