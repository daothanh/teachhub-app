import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/theme/teachhub_theme.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/features/role_picker/role_picker_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _Cubit extends MembershipCubit {
  _Cubit(SharedPreferences prefs)
    : super(api: Dio(), prefs: prefs, activeMembership: ActiveMembership(null));
  final added = <MembershipRole>[];
  var resets = 0;
  @override
  void resetPendingAdd() => resets++;
  @override
  Future<void> addRole(MembershipRole role) async => added.add(role);
}

void main() {
  testWidgets('T01c (B04→B05): chọn thẻ → "Đã chọn", Tiếp tục tạo vai trò', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = _Cubit(await SharedPreferences.getInstance());
    addTearDown(cubit.close);
    final themes = await tester.runAsync(TeachHubTheme.load);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(393, 852),
        builder: (_, _) => MaterialApp.router(
          locale: const Locale('vi'),
          theme: themes!.light,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            TascoUiKitLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => BlocProvider<MembershipCubit>.value(
                  value: cubit,
                  child: const RolePickerPage(),
                ),
              ),
              GoRoute(
                path: AppRoutes.centerWaitlist,
                builder: (_, _) => const Text('waitlist'),
              ),
            ],
          ),
        ),
      ),
    );

    Finder cont() => find.ancestor(
      of: find.text('Tiếp tục'),
      matching: find.byType(AppButton),
    );
    expect(find.text('Bạn là…?'), findsOneWidget);
    expect(find.text('Sắp ra mắt'), findsOneWidget);
    expect(find.text('Đã chọn'), findsNothing);
    expect(tester.widget<AppButton>(cont()).disabled, isTrue);

    await tester.tap(find.text('Phụ huynh'));
    await tester.pump();
    expect(find.text('Đã chọn'), findsOneWidget);
    expect(cubit.resets, 1, reason: 'đổi lựa chọn = đổi ý, bỏ khóa dở');

    await tester.tap(cont());
    await tester.pump();
    expect(cubit.added, [MembershipRole.parent]);
  });

  testWidgets('T01c: chạm thẻ Chủ trung tâm mở màn đăng ký sớm (T01d)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = _Cubit(await SharedPreferences.getInstance());
    addTearDown(cubit.close);
    final themes = await tester.runAsync(TeachHubTheme.load);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(393, 852),
        builder: (_, _) => MaterialApp.router(
          locale: const Locale('vi'),
          theme: themes!.light,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            TascoUiKitLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => BlocProvider<MembershipCubit>.value(
                  value: cubit,
                  child: const RolePickerPage(),
                ),
              ),
              GoRoute(
                path: AppRoutes.centerWaitlist,
                builder: (_, _) => const Text('waitlist'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Chủ trung tâm'));
    await tester.pumpAndSettle();
    expect(find.text('waitlist'), findsOneWidget);
  });
}
