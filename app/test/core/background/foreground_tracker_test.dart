import 'package:app/core/background/foreground_tracker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/teacher.dart';

void main() {
  testWidgets('ghi cờ foreground theo vòng đời app', (tester) async {
    final keys = InMemoryKeyValueStore();
    final tracker = ForegroundTracker(keys)..start();
    addTearDown(tracker.stop);
    await tester.pump();
    expect(await isForeground(keys), isTrue);
    tracker.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump();
    expect(await isForeground(keys), isFalse);
    tracker.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(await isForeground(keys), isTrue);
  });
}
