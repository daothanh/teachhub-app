import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/offline/offline_banner_shell.dart';
import 'package:teacher/l10n/l10n.dart';

import '../../support/pump_app.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester,
    String path,
    Stream<bool> online,
  ) => pumpApp(
    tester,
    OfflineBannerShell(
      path: path,
      online: online,
      child: const Scaffold(body: Text('trang')),
    ),
  );

  Finder banner(WidgetTester tester) => find.text(
    MiniAppLocalizations.of(
      tester.element(find.byType(Scaffold)),
    ).offlineBanner,
  );

  testWidgets('ngoại tuyến: hiện banner phía trên màn', (tester) async {
    await pumpShell(tester, '/t/classes', Stream.value(false));
    expect(banner(tester), findsOneWidget);
    expect(find.text('trang'), findsOneWidget);
  });

  testWidgets('có mạng: không có banner', (tester) async {
    await pumpShell(tester, '/t/classes', Stream.value(true));
    expect(find.textContaining('Ngoại tuyến'), findsNothing);
  });

  testWidgets('T03 và T04 đã có banner riêng: shell không vẽ thêm', (
    tester,
  ) async {
    for (final path in ['/t', '/t/sessions/abc/attendance']) {
      await pumpShell(tester, path, Stream.value(false));
      expect(find.textContaining('Ngoại tuyến'), findsNothing, reason: path);
    }
    expect(hasOwnOfflineBanner('/t/sessions/abc/attendance/history'), isFalse);
    expect(hasOwnOfflineBanner('/t/classes'), isFalse);
  });
}
