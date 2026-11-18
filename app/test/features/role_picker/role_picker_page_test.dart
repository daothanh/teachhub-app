import 'package:app/core/theme/teachhub_theme.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/features/role_picker/role_picker_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _Cubit extends MembershipCubit {
  _Cubit(SharedPreferences prefs)
    : super(api: Dio(), prefs: prefs, activeMembership: ActiveMembership(null));
  final added = <MembershipRole>[];
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
        builder: (_, _) => MaterialApp(
          locale: const Locale('vi'),
          theme: themes!.light,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            TascoUiKitLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<MembershipCubit>.value(
            value: cubit,
            child: const RolePickerPage(),
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

    // Chủ trung tâm chưa mở: chạm không chọn được.
    await tester.tap(find.text('Chủ trung tâm'));
    await tester.pump();
    expect(find.text('Đã chọn'), findsOneWidget);

    await tester.tap(cont());
    await tester.pump();
    expect(cubit.added, [MembershipRole.parent]);
  });
}
