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

  testWidgets(
    'C20 một vai trò: chỉ hiện tên, không có ▾, chạm không mở sheet',
    (tester) async {
      await pumpShell(tester, [_teacher]);
      expect(find.text('Giáo viên'), findsOneWidget);
      expect(find.byIcon(TeachHubIcons.caretDown), findsNothing);
      await tester.tap(find.text('Giáo viên'));
      await tester.pumpAndSettle();
      expect(find.text('Chuyển vai trò'), findsNothing);
    },
  );

  testWidgets(
    'T00: sheet liệt kê vai trò, ✓ vai trò đang mở, chạm vai trò khác → chuyển',
    (tester) async {
      final cubit = await pumpShell(tester, [_teacher, _parent]);
      expect(find.text('space:t'), findsOneWidget);
      expect(find.byIcon(TeachHubIcons.caretDown), findsOneWidget);

      await tester.tap(find.text('Giáo viên'));
      await tester.pumpAndSettle();
      expect(find.text('Chuyển vai trò'), findsOneWidget);
      expect(find.text('Cô Lan'), findsOneWidget); // phạm vi lấy từ nhãn API
      expect(find.byIcon(TeachHubIcons.check), findsOneWidget);

      // Vai trò đang mở không bấm được.
      await tester.tap(find.text('Cô Lan'));
      await tester.pumpAndSettle();
      expect(cubit.selected, isEmpty);

      await tester.tap(find.text('Phụ huynh').last);
      await tester.pumpAndSettle();
      expect(cubit.selected, [_parent]);
      expect(find.text('space:p'), findsOneWidget);
      expect(find.text('Đang ở vai trò Phụ huynh'), findsOneWidget);
      expect(find.text('Chuyển vai trò'), findsNothing);
    },
  );

  testWidgets('T00: "+ Thêm vai trò" mở T01c', (tester) async {
    await pumpShell(tester, [_teacher, _parent]);
    await tester.tap(find.text('Giáo viên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm vai trò'));
    await tester.pumpAndSettle();
    expect(find.text('role-picker'), findsOneWidget);
  });
}
