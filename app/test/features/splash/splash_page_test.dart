import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('vi')}) {
  return ScreenUtilPlusInit(
    designSize: const Size(393, 852),
    builder: (context, _) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.v1,
      home: child,
    ),
  );
}

void main() {
  group('SplashPage Widget Tests', () {
    testWidgets(
      'renders brand logo, loading indicator, and footer strings in vi',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(const SplashPage()));
        await tester.pump();

        // Check loading indicator is rendered
        expect(find.byType(AppLoading), findsOneWidget);

        // Check footer tagline and copyright
        expect(find.text('Hệ sinh thái Tasco'), findsOneWidget);
        expect(find.text('© 2026 Tasco Joint Stock Company'), findsOneWidget);

        // Check AppSvgIcon logo exists
        expect(find.byType(AppSvgIcon), findsOneWidget);
      },
    );

    testWidgets('renders footer strings properly in en locale', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(const SplashPage(), locale: const Locale('en')),
      );
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('Tasco Ecosystem'), findsOneWidget);
      expect(find.text('© 2026 Tasco Joint Stock Company'), findsOneWidget);
    });

    testWidgets('renders gradient background container', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const SplashPage()));
      await tester.pump();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final containerFinder = find.descendant(
        of: scaffoldFinder,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });
  });
}
