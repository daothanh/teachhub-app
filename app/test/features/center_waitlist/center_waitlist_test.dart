import 'dart:convert';
import 'dart:io';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/center_waitlist/center_waitlist_cubit.dart';
import 'package:app/features/center_waitlist/center_waitlist_page.dart';
import 'package:app/features/center_waitlist/center_waitlist_repository.dart';
import 'package:app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _FakeRepo implements CenterWaitlistRepository {
  _FakeRepo([this.error]);
  final Object? error;
  final calls = <({String name, int count})>[];
  final keys = <String>[];

  @override
  Future<void> join({
    required String centerName,
    required int teacherCount,
    required String idempotencyKey,
  }) async {
    calls.add((name: centerName, count: teacherCount));
    keys.add(idempotencyKey);
    if (error != null) throw error!;
  }
}

Future<GoRouter> _open(WidgetTester tester, _FakeRepo repo) async {
  tester.view.physicalSize = const Size(390, 1200) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.centerWaitlist,
    routes: [
      GoRoute(
        path: AppRoutes.centerWaitlist,
        builder: (_, _) => BlocProvider(
          create: (_) => CenterWaitlistCubit(repo),
          child: const CenterWaitlistPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.rolePicker,
        builder: (_, _) => const Text('role-picker'),
      ),
    ],
  );
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
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _fill(WidgetTester tester, String name, String count) async {
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), count);
  await tester.tap(find.text('Gửi đăng ký'));
  await tester.pumpAndSettle();
}

void main() {
  test('thân POST /center-waitlist khớp hợp đồng', () {
    final openapi =
        jsonDecode(
              File(
                '../packages/teachhub_shared/contracts/openapi.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final body =
        openapi['paths']['/v1/center-waitlist']['post']['requestBody']['content']['application/json']['schema']
            as Map;
    expect((body['properties'] as Map).keys, {'centerName', 'teacherCount'});
    expect(body['required'], ['centerName', 'teacherCount']);
    expect(body['properties']['teacherCount']['minimum'], 1);
    expect(body['properties']['teacherCount']['maximum'], 1000);
  });

  testWidgets('đường chính: gửi tên + số GV, rồi về T01c để chọn Giáo viên', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    expect(
      find.text('Trong lúc chờ, bạn có thể dùng thử với vai trò Giáo viên.'),
      findsOneWidget,
    );
    await _fill(tester, 'Trung tâm Ánh Dương', '8');

    expect(repo.calls.single, (name: 'Trung tâm Ánh Dương', count: 8));
    expect(find.text('Đã nhận đăng ký'), findsOneWidget);

    await tester.tap(find.text('Dùng thử vai trò Giáo viên'));
    await tester.pumpAndSettle();
    expect(find.text('role-picker'), findsOneWidget);
  });

  testWidgets('nhập sai: báo tại ô, không gọi API', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await _fill(tester, '', '0');
    expect(find.text('Nhập tên trung tâm.'), findsOneWidget);
    expect(find.text('Nhập số từ 1 đến 1000.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  for (final (status, code, message) in [
    (
      409,
      'IDEMPOTENCY_IN_PROGRESS',
      'Yêu cầu đang xử lý. Thử lại sau giây lát.',
    ),
    (422, 'VALIDATION_FAILED', 'Thông tin chưa hợp lệ. Kiểm tra lại các ô.'),
  ]) {
    testWidgets('$status $code: thông báo, form giữ nguyên', (tester) async {
      await _open(
        tester,
        _FakeRepo(ApiException.fromResponse(status, {'code': code})),
      );
      await _fill(tester, 'TT A', '3');
      expect(find.text(message), findsOneWidget);
      expect(find.text('Gửi đăng ký'), findsOneWidget);
    });
  }

  test(
    'Idempotency-Key: thử lại cùng nội dung giữ khóa, đổi nội dung khóa mới',
    () async {
      final repo = _FakeRepo(const ApiException.network());
      final cubit = CenterWaitlistCubit(repo);
      addTearDown(cubit.close);
      await cubit.submit(centerName: 'A', teacherCount: 3);
      await cubit.submit(centerName: 'A', teacherCount: 3);
      await cubit.submit(centerName: 'A', teacherCount: 4);
      expect(repo.keys[0], repo.keys[1]);
      expect(repo.keys[2], isNot(repo.keys[0]));
    },
  );

  testWidgets('"Dùng thử" có sẵn ngay trên form, không cần gửi', (
    tester,
  ) async {
    await _open(tester, _FakeRepo());
    await tester.ensureVisible(find.text('Dùng thử vai trò Giáo viên'));
    await tester.tap(find.text('Dùng thử vai trò Giáo viên'));
    await tester.pumpAndSettle();
    expect(find.text('role-picker'), findsOneWidget);
  });
}
