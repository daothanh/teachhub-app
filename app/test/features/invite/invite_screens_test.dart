import 'package:app/features/consent/consent_cubit.dart';
import 'package:app/features/consent/consent_page.dart';
import 'package:app/features/invite/invite_cubit.dart';
import 'package:app/features/invite/invite_entry_cubit.dart';
import 'package:app/features/invite/invite_entry_view.dart';
import 'package:app/features/invite/invite_link_requester.dart';
import 'package:app/features/invite/invite_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'invite_fakes.dart';

const _token = 'q3Zp8mT1xV0kLw5Hn2RcYb7JdFgSaE9uXoIiKtUeMhA';

class _Requester extends InviteLinkRequester {
  _Requester(this.log);
  final List<String> log;
  @override
  Future<InviteLinkRequestOutcome> request(String message) async {
    log.add(message);
    return InviteLinkRequestOutcome.zaloOpened;
  }
}

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(393, 852),
      builder: (_, _) => MaterialApp.router(
        locale: const Locale('vi'),
        theme: AppTheme.v1,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          TascoUiKitLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Màn đồng ý giả: có nút đồng ý (pop true) và nút từ chối (pop null).
GoRoute _consentStub() => GoRoute(
  path: '/consent',
  builder: (context, _) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () => context.pop(true),
          child: const Text('đồng ý'),
        ),
        TextButton(onPressed: context.pop, child: const Text('từ chối')),
      ],
    ),
  ),
);

void main() {
  late FakeInviteRepository repo;
  late FakeMemberships memberships;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = FakeInviteRepository();
    memberships = FakeMemberships(await SharedPreferences.getInstance());
  });

  group('InvitePage', () {
    final requesterLog = <String>[];
    setUp(requesterLog.clear);

    GoRouter router() => GoRouter(
      initialLocation: '/invite/$_token',
      routes: [
        GoRoute(
          path: '/invite/:token',
          builder: (_, state) => BlocProvider(
            create: (_) => InviteCubit(
              repository: repo,
              memberships: memberships,
              consent: fakeConsent(),
              token: state.pathParameters['token']!,
            ),
            child: InvitePage(requester: _Requester(requesterLog)),
          ),
        ),
        _consentStub(),
        GoRoute(
          path: TeachHubRoutes.parent,
          builder: (_, _) => const Text('P02'),
        ),
      ],
    );

    testWidgets('thẻ lời mời → đồng ý điều khoản → nhận lời mời → P02', (
      tester,
    ) async {
      repo.previews.add(samplePreview);
      repo.accepts
        ..add(apiError(403, 'CONSENT_REQUIRED'))
        ..add(FakeInviteRepository.accepted);
      await _pump(tester, router());

      expect(find.text('Lời mời từ Cô Lan'), findsOneWidget);
      expect(find.textContaining('Anh'), findsWidgets);

      await tester.tap(find.text('Nhận lời mời'));
      await tester.pumpAndSettle();
      expect(find.text('đồng ý'), findsOneWidget);

      await tester.tap(find.text('đồng ý'));
      await tester.pumpAndSettle();
      expect(find.text('P02'), findsOneWidget);
      expect(memberships.selected, ['m-p']);
      expect(repo.calls, [
        'preview:$_token',
        'accept:$_token',
        'accept:$_token',
      ]);
    });

    testWidgets('từ chối đồng ý: ở lại thẻ lời mời, không vào P02', (
      tester,
    ) async {
      repo.previews.add(samplePreview);
      repo.accepts.add(apiError(403, 'CONSENT_REQUIRED'));
      await _pump(tester, router());
      await tester.tap(find.text('Nhận lời mời'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('từ chối'));
      await tester.pumpAndSettle();
      expect(find.text('Lời mời từ Cô Lan'), findsOneWidget);
      expect(find.text('P02'), findsNothing);
    });

    testWidgets('link hết hạn: báo hết hạn kèm nút nhắn giáo viên xin link', (
      tester,
    ) async {
      repo.previews.add(apiError(410, 'INVITE_INVALID'));
      await _pump(tester, router());
      expect(find.textContaining('hết hạn'), findsOneWidget);
      await tester.tap(find.text('Nhắn giáo viên xin link'));
      await tester.pumpAndSettle();
      expect(requesterLog, [
        lookupAppLocalizations(const Locale('vi')).inviteAskMessage,
      ]);
    });
  });

  group('InviteEntryView (P05)', () {
    final requesterLog = <String>[];
    setUp(requesterLog.clear);

    GoRouter router({VoidCallback? onLinked}) => GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (_, _) => Scaffold(
            body: BlocProvider(
              create: (_) => InviteEntryCubit(
                repository: repo,
                memberships: memberships,
                consent: fakeConsent(),
              ),
              child: InviteEntryView(
                onLinked: onLinked ?? () {},
                requester: _Requester(requesterLog),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/invite/:token',
          builder: (_, s) => Text('card ${s.pathParameters['token']}'),
        ),
        GoRoute(path: '/invite/scan', builder: (_, _) => const Text('scanner')),
        _consentStub(),
      ],
    );

    testWidgets('giải thích và đủ 3 cách; không có tìm theo tên/SĐT', (
      tester,
    ) async {
      await _pump(tester, router());
      expect(find.text('Cần lời mời từ giáo viên'), findsOneWidget);
      expect(find.text('Quét mã QR'), findsOneWidget);
      expect(find.text('Dán link hoặc nhập mã mời'), findsOneWidget);
      expect(find.text('Nhắn giáo viên xin link'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('dán link #t=<token> → mở thẻ lời mời', (tester) async {
      await _pump(tester, router());
      await tester.enterText(
        find.byType(TextField),
        'https://dayhoc.app/i#t=$_token',
      );
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('card $_token'), findsOneWidget);
    });

    testWidgets('nhập linh tinh → báo chưa nhận ra, không gọi API', (
      tester,
    ) async {
      await _pump(tester, router());
      await tester.enterText(find.byType(TextField), 'xin chào');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa nhận ra'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('mã đúng → nhận lời mời → onLinked', (tester) async {
      var linked = 0;
      repo.redeems.add(FakeInviteRepository.accepted);
      await _pump(tester, router(onLinked: () => linked++));
      await tester.enterText(find.byType(TextField), '7k3q-z9xm');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['redeem:7k3qz9xm']);
      expect(linked, 1);
    });

    testWidgets('mã sai: báo mã không đúng', (tester) async {
      repo.redeems.add(apiError(410, 'INVITE_INVALID'));
      await _pump(tester, router());
      await tester.enterText(find.byType(TextField), '7K3QZ9XM');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mã không đúng'), findsOneWidget);
    });

    testWidgets('sai 5 lần → 429 INVITE_CODE_LOCKED: hiện bị khóa, chặn nhập', (
      tester,
    ) async {
      repo.redeems.add(
        apiError(429, 'INVITE_CODE_LOCKED', details: {'retryAfterSec': 900}),
      );
      await _pump(tester, router());
      await tester.enterText(find.byType(TextField), '7K3QZ9XM');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Thử lại sau 15 phút'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp tục'),
      );
      expect(button.onPressed, isNull);
      // Hủy Timer mở khóa còn treo của cubit.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('mã cần đồng ý điều khoản: đồng ý xong tự nhận lại', (
      tester,
    ) async {
      var linked = 0;
      repo.redeems
        ..add(apiError(403, 'CONSENT_REQUIRED'))
        ..add(FakeInviteRepository.accepted);
      await _pump(tester, router(onLinked: () => linked++));
      await tester.enterText(find.byType(TextField), '7K3QZ9XM');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('đồng ý'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['redeem:7K3QZ9XM', 'redeem:7K3QZ9XM']);
      expect(linked, 1);
    });

    testWidgets('Nhắn giáo viên xin link: gửi tin soạn sẵn qua requester', (
      tester,
    ) async {
      await _pump(tester, router());
      await tester.tap(find.text('Nhắn giáo viên xin link'));
      await tester.pumpAndSettle();
      expect(requesterLog.single, contains('TeachHub'));
      expect(find.textContaining('Đã sao chép tin nhắn'), findsOneWidget);
    });

    testWidgets(
      'textScale 2.0 không tràn, nút có nhãn cho trình đọc màn hình',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, router(), textScale: 2);
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Quét mã QR'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Nhắn giáo viên xin link'),
          findsOneWidget,
        );
        handle.dispose();
      },
    );
  });

  group('ConsentPage', () {
    testWidgets(
      'textScale 2.0 không tràn; đồng ý xong → pop(true) cho luồng gọi',
      (tester) async {
        final consent = fakeConsent()..markRequired('2026-12-01');
        Object? result = 'chưa';
        final router = GoRouter(
          initialLocation: '/start',
          routes: [
            GoRoute(
              path: '/start',
              builder: (context, _) => TextButton(
                onPressed: () async =>
                    result = await context.push<bool>('/consent'),
                child: const Text('mở'),
              ),
            ),
            GoRoute(
              path: '/consent',
              builder: (_, _) => BlocProvider.value(
                value: consent,
                child: const ConsentPage(),
              ),
            ),
          ],
        );
        await _pump(tester, router, textScale: 2);
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('2026-12-01'), findsOneWidget);

        consent.markAccepted(); // server đã ghi đồng ý
        await tester.pumpAndSettle();
        expect(result, isTrue);
        expect(consent.state.phase, ConsentPhase.accepted);
      },
    );
  });
}
