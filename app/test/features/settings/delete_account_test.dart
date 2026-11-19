import 'dart:convert';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/settings/delete_account/account_repository.dart';
import 'package:app/features/settings/delete_account/delete_account_cubit.dart';
import 'package:app/features/settings/delete_account/delete_account_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/l10n/l10n.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _FakeAccountRepo implements AccountRepository {
  final calls = <String>[];
  final keys = <String>[];
  final sendErrors = <Object>[];
  final deleteErrors = <Object>[];

  @override
  Future<void> sendDeleteOtp(String email) async {
    calls.add('otp:$email');
    if (sendErrors.isNotEmpty) throw sendErrors.removeAt(0);
  }

  @override
  Future<void> deleteAccount({
    required String otp,
    required String idempotencyKey,
  }) async {
    calls.add('delete:$otp');
    keys.add(idempotencyKey);
    if (deleteErrors.isNotEmpty) throw deleteErrors.removeAt(0);
  }
}

ApiException _err(int status, String code, [Map<String, Object?>? details]) =>
    ApiException.fromResponse(status, {
      'code': code,
      'message': 'x',
      'details': ?details,
    });

DeleteAccountCubit _cubit(
  _FakeAccountRepo repo, {
  int? pending = 0,
  List<String>? finished,
}) => DeleteAccountCubit(
  repository: repo,
  pendingCount: () async => pending,
  finish: () async => finished?.add('finish'),
);

void main() {
  group('DeleteAccountCubit', () {
    test('đường chính: gửi mã, nhập mã, xóa rồi dọn máy', () async {
      final repo = _FakeAccountRepo();
      final finished = <String>[];
      final c = _cubit(repo, finished: finished);
      await c.sendCode('a@b.vn');
      expect(c.state.step, DeleteStep.code);
      await c.confirm('123456');
      expect(repo.calls, ['otp:a@b.vn', 'delete:123456']);
      expect(finished, ['finish']);
      expect(c.state.step, DeleteStep.done);
    });

    test('OTP sai: báo còn mấy lần, không dọn máy', () async {
      final repo = _FakeAccountRepo()
        ..deleteErrors.add(_err(401, 'OTP_INVALID', {'attemptsLeft': 3}));
      final finished = <String>[];
      final c = _cubit(repo, finished: finished);
      await c.sendCode('a@b.vn');
      await c.confirm('000000');
      expect(c.state.failure, DeleteFailure.otpInvalid);
      expect(c.state.attemptsLeft, 3);
      expect(finished, isEmpty);
      expect(c.state.step, DeleteStep.code);
    });

    test('OTP bị khóa (429 OTP_LOCKED)', () async {
      final repo = _FakeAccountRepo()
        ..deleteErrors.add(_err(429, 'OTP_LOCKED'));
      final c = _cubit(repo);
      await c.sendCode('a@b.vn');
      await c.confirm('000000');
      expect(c.state.failure, DeleteFailure.otpLocked);
    });

    test('gửi mã bị giới hạn (429) kèm thời gian chờ', () async {
      final repo = _FakeAccountRepo()
        ..sendErrors.add(_err(429, 'RATE_LIMITED', {'retryAfterSec': 42}));
      final c = _cubit(repo);
      await c.sendCode('a@b.vn');
      expect(c.state.failure, DeleteFailure.rateLimited);
      expect(c.state.retryAfterSec, 42);
      expect(c.state.step, DeleteStep.confirm);
    });

    for (final (reason, expected) in [
      ('OWNER_HAS_STAFF', DeleteFailure.ownerHasStaff),
      ('TENANT_HAS_ACTIVE_CLASSES', DeleteFailure.tenantHasActiveClasses),
      ('LA', DeleteFailure.stale),
    ]) {
      test('409 CONFLICT_STALE reason=$reason', () async {
        final repo = _FakeAccountRepo()
          ..deleteErrors.add(_err(409, 'CONFLICT_STALE', {'reason': reason}));
        final finished = <String>[];
        final c = _cubit(repo, finished: finished);
        await c.sendCode('a@b.vn');
        await c.confirm('123456');
        expect(c.state.failure, expected);
        expect(finished, isEmpty);
      });
    }

    test(
      'lỗi mạng giữ Idempotency-Key khi thử lại cùng mã; mã khác khóa mới',
      () async {
        final repo = _FakeAccountRepo()
          ..deleteErrors.add(const ApiException.network());
        final c = _cubit(repo);
        await c.sendCode('a@b.vn');
        await c.confirm('123456');
        expect(c.state.failure, DeleteFailure.network);
        await c.confirm('123456');
        expect(repo.keys[1], repo.keys[0]);
        expect(c.state.step, DeleteStep.done);

        final repo2 = _FakeAccountRepo()
          ..deleteErrors.add(_err(401, 'OTP_INVALID'));
        final c2 = _cubit(repo2);
        await c2.sendCode('a@b.vn');
        await c2.confirm('111111');
        await c2.confirm('222222');
        expect(repo2.keys[1], isNot(repo2.keys[0]));
      },
    );

    test('lỗi dọn máy sau khi server đã xóa vẫn coi là xong', () async {
      final repo = _FakeAccountRepo();
      final c = DeleteAccountCubit(
        repository: repo,
        pendingCount: () async => 0,
        finish: () async => throw StateError('disk'),
      );
      await c.sendCode('a@b.vn');
      await c.confirm('123456');
      expect(c.state.step, DeleteStep.done);
    });
  });

  group('DioAccountRepository', () {
    test(
      'DELETE /me gửi otp và Idempotency-Key; OTP gửi purpose delete_account',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://x/v1'));
        final seen = <RequestOptions>[];
        dio.httpClientAdapter = _Adapter(seen);
        final repo = DioAccountRepository(dio);
        await repo.sendDeleteOtp('a@b.vn');
        await repo.deleteAccount(otp: '123456', idempotencyKey: 'k-1');
        expect(seen[0].path, '/auth/otp/send');
        expect(seen[0].data, {'email': 'a@b.vn', 'purpose': 'delete_account'});
        expect(seen[1].method, 'DELETE');
        expect(seen[1].path, '/me');
        expect(seen[1].data, {'otp': '123456'});
        expect(seen[1].headers['Idempotency-Key'], 'k-1');
      },
    );
  });

  group('DeleteAccountPage', () {
    Future<GoRouter> open(
      WidgetTester tester,
      DeleteAccountCubit cubit, {
      double scale = 1,
    }) async {
      tester.view.physicalSize = const Size(390, 1200) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: AppRoutes.deleteAccount,
        routes: [
          GoRoute(
            path: AppRoutes.deleteAccount,
            builder: (_, _) =>
                DeleteAccountScope(email: 'a@b.vn', cubit: cubit),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (_, _) => const Text('login-page'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(393, 852),
          builder: (_, _) => MaterialApp.router(
            locale: const Locale('vi'),
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              TascoUiKitLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.v1,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('cảnh báo outbox, gửi mã, nhập mã, xóa rồi về đăng nhập', (
      tester,
    ) async {
      final repo = _FakeAccountRepo();
      final finished = <String>[];
      await open(tester, _cubit(repo, pending: 3, finished: finished));
      expect(find.text('Hành động này không thể hoàn tác'), findsOneWidget);
      expect(find.textContaining('3 mục chưa đồng bộ'), findsOneWidget);

      await tester.tap(find.text('Gửi mã xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['otp:a@b.vn']);

      await tester.enterText(find.byType(EditableText).first, '123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa tài khoản vĩnh viễn'));
      await tester.pumpAndSettle();

      expect(repo.calls.last, 'delete:123456');
      expect(finished, ['finish']);
      expect(find.text('login-page'), findsOneWidget);
    });

    testWidgets('409 còn lớp đang hoạt động: hướng dẫn lưu trữ lớp', (
      tester,
    ) async {
      final repo = _FakeAccountRepo()
        ..deleteErrors.add(
          _err(409, 'CONFLICT_STALE', {'reason': 'TENANT_HAS_ACTIVE_CLASSES'}),
        );
      await open(tester, _cubit(repo));
      await tester.tap(find.text('Gửi mã xác nhận'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, '123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa tài khoản vĩnh viễn'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hãy lưu trữ hết các lớp'), findsOneWidget);
      expect(find.text('login-page'), findsNothing);
    });

    testWidgets('chữ 200%: cả hai bước không vỡ bố cục', (tester) async {
      final repo = _FakeAccountRepo();
      await open(tester, _cubit(repo, pending: null), scale: 2);
      expect(find.textContaining('Không kiểm tra được'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi mã xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['otp:a@b.vn']);
      expect(find.text('Nhập mã xác nhận'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.seen);
  final List<RequestOptions> seen;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return ResponseBody.fromString(jsonEncode({}), 204);
  }

  @override
  void close({bool force = false}) {}
}
