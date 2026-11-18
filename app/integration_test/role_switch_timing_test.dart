// S1-FL-08 / US-0.11 AC1: đo thời gian chuyển vai trò trên MÁY THẬT (từ lúc chạm vai trò trong T00
// tới khi không gian mới hiện xong, gồm hiệu ứng đóng sheet + chuyển trang). Bản debug — release nhanh hơn.
//   flutter test integration_test/role_switch_timing_test.dart -d <máy> --flavor development
import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/theme/teachhub_theme.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/features/role_picker/role_switcher.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const _teacher = Membership(
  id: 'm-t',
  role: MembershipRole.tenantOwner,
  label: 'Giáo viên · Cô Lan',
  tenantId: 't-1',
);
const _parent = Membership(
  id: 'm-p',
  role: MembershipRole.parent,
  label: 'Phụ huynh',
);

/// Cubit có sẵn vai trò, ghi lại lần chọn (không gọi API).
class _Cubit extends MembershipCubit {
  _Cubit(SharedPreferences prefs, List<Membership> items)
    : super(
        api: Dio(),
        prefs: prefs,
        activeMembership: ActiveMembership(null),
      ) {
    emit(state.copyWith(memberships: items, active: items.first));
  }
  final selected = <Membership>[];
  @override
  Future<void> select(Membership membership) async {
    selected.add(membership);
    emit(state.copyWith(active: membership));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late ThemeData theme;

  Future<_Cubit> pumpShell(WidgetTester tester, List<Membership> items) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = _Cubit(await SharedPreferences.getInstance(), items);
    addTearDown(cubit.close);
    theme = (await tester.runAsync(TeachHubTheme.load))!.light;
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Trang gốc giả của mỗi không gian: App Bar đặt chip như mini-app thật.
    Widget space(String name) => Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: RoleSwitcherScope.chipOf(context)),
        body: Text('space:$name'),
      ),
    );
    final router = GoRouter(
      initialLocation: items.first.role.rootRoute,
      routes: [
        GoRoute(path: TeachHubRoutes.teacher, builder: (_, _) => space('t')),
        GoRoute(path: TeachHubRoutes.parent, builder: (_, _) => space('p')),
        GoRoute(path: TeachHubRoutes.student, builder: (_, _) => space('s')),
        GoRoute(
          path: AppRoutes.rolePicker,
          builder: (_, _) => const Text('role-picker'),
        ),
      ],
    );
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(393, 852),
        builder: (_, _) => BlocProvider<MembershipCubit>.value(
          value: cubit,
          child: RoleSwitcherScope(
            chip: (_) => const RoleChip(),
            child: MaterialApp.router(
              locale: const Locale('vi'),
              theme: theme,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                TascoUiKitLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('chuyển vai trò ≤ 1 giây', (tester) async {
    await pumpShell(tester, [_teacher, _parent]);
    final ms = <int>[];
    for (var i = 0; i < 10; i++) {
      final from = i.isEven ? 'Giáo viên' : 'Phụ huynh';
      final to = i.isEven ? 'Phụ huynh' : 'Giáo viên';
      await tester.tap(find.text(from).first);
      await tester.pumpAndSettle();
      final sw = Stopwatch()..start();
      await tester.tap(find.text(to).last);
      await tester.pumpAndSettle();
      sw.stop();
      expect(find.text(i.isEven ? 'space:p' : 'space:t'), findsOneWidget);
      ms.add(sw.elapsedMilliseconds);
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    }
    ms.sort();
    // ignore: avoid_print
    print(
      'ROLE_SWITCH ms (sorted): $ms median=${ms[ms.length ~/ 2]} max=${ms.last}',
    );
    expect(ms.last, lessThanOrEqualTo(1000));
  });
}
