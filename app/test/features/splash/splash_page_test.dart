import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/brand_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _Cubit extends MembershipCubit {
  _Cubit(SharedPreferences prefs, MembershipState initial)
    : super(
        api: Dio(),
        prefs: prefs,
        activeMembership: ActiveMembership(null),
      ) {
    emit(initial);
  }
  int loads = 0;
  @override
  Future<void> load({bool silent = false}) async => loads++;
}

Future<_Cubit> _pump(WidgetTester tester, MembershipState state) async {
  SharedPreferences.setMockInitialValues({});
  final cubit = _Cubit(await SharedPreferences.getInstance(), state);
  addTearDown(cubit.close);
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(393, 852),
      builder: (_, _) => MaterialApp(
        locale: const Locale('vi'),
        theme: AppTheme.v1,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          TascoUiKitLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<MembershipCubit>.value(
          value: cubit,
          child: const SplashPage(),
        ),
      ),
    ),
  );
  return cubit;
}

void main() {
  testWidgets('B00a: mark, tên app và khẩu hiệu trên nền thương hiệu', (
    tester,
  ) async {
    await _pump(
      tester,
      const MembershipState(statusLoad: LoadingStatus.loading),
    );
    expect(find.text('DayHoc'), findsOneWidget);
    // Logo mới là hình vector (D + chấm nặng), không còn chữ "D" bằng font.
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(
      find.textContaining('Kết nối thầy, trò và gia đình.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('a failed role load offers a retry', (tester) async {
    final cubit = await _pump(
      tester,
      const MembershipState(statusLoad: LoadingStatus.failure),
    );
    expect(find.text('Không tải được vai trò của bạn.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(cubit.loads, 1);
  });
}
