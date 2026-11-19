import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/l10n/l10n.dart';

/// Dựng [home] trong MaterialApp tiếng Việt với theme của kit.
Future<void> pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 1400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          ...MiniAppLocalizations.localizationsDelegates,
          TascoUiKitLocalizations.delegate,
        ],
        supportedLocales: MiniAppLocalizations.supportedLocales,
        theme: AppTheme.v1,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
