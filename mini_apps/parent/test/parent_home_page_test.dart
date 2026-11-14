import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';
import 'package:parent/parent.dart';
import 'package:parent/l10n/l10n.dart';

void main() {
  testWidgets('root route shows the space and switches role via the shell', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: TeachHubRoutes.parent,
      routes: [
        ...ParentController.instance.routes(),
        GoRoute(
          path: TeachHubRoutes.rolePicker,
          builder: (_, _) => const Text('role-picker'),
        ),
      ],
    );
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(393, 852),
        builder: (context, _) => MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [
            ...MiniAppLocalizations.localizationsDelegates,
            TascoUiKitLocalizations.delegate,
          ],
          supportedLocales: MiniAppLocalizations.supportedLocales,
          theme: AppTheme.v1,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parent'), findsWidgets);
    await tester.tap(find.text('Switch role'));
    await tester.pumpAndSettle();
    expect(find.text('role-picker'), findsOneWidget);
  });
}
