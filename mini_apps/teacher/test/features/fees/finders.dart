import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

Finder inputOf(String label) => find.byWidgetPredicate(
  (w) => w is AppInput && w.label == label,
  skipOffstage: false,
);

Finder fieldOf(String label) =>
    find.descendant(of: inputOf(label), matching: find.byType(EditableText));

/// Cuộn tới khi widget được dựng rồi mới thao tác (danh sách dựng lười).
Future<void> reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

/// Nhiều ô cùng nhãn (hàng miễn giảm): `last` thao tác ô cuối.
Future<void> tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  final plain = find.text(text);
  // Nhiều ô cùng nhãn đã được dựng thì khỏi cuộn (scrollUntilVisible cần 1 ô).
  if (plain.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      plain,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final all = plain.evaluate().toList();
  final f = find.byWidget((last ? all.last : all.first).widget);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final f = find.widgetWithText(AppButton, label);
  await reveal(tester, f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}
