import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:parent/features/family/data/family_models.dart';
import 'package:parent/features/family/data/family_repository.dart';
import 'package:parent/l10n/l10n.dart';
import 'package:parent/parent.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

FamilyStudent _child(String id, String name) => FamilyStudent(
  id: id,
  fullName: name,
  classes: const [
    FamilyClass(id: 'c1', name: 'Toán 9A', teacherName: 'Cô Lan'),
  ],
);

AttendanceWeek _week(String id, {int present = 1}) => AttendanceWeek(
  studentId: id,
  weekStart: DateTime(2026, 12, 14),
  weekEnd: DateTime(2026, 12, 20),
  summary: AttendanceSummary(
    present: present,
    late: 0,
    excused: 0,
    unexcused: 1,
    notRecorded: 0,
    upcoming: 0,
  ),
  sessions: [
    AttendanceSession(
      sessionId: 's-$id',
      className: 'Toán 9A',
      startsAt: DateTime(2026, 12, 15, 18),
      cancelled: false,
      isMakeup: false,
      mark: AttendanceMark.present,
    ),
  ],
);

class _FakeRepo implements FamilyRepository {
  _FakeRepo(this.children);
  final List<FamilyStudent> children;
  final weekCalls = <String>[];
  bool failStudents = false;

  @override
  Future<List<FamilyStudent>> students() async {
    if (failStudents) throw const ApiException.network();
    return children;
  }

  @override
  Future<AttendanceWeek> attendance(String studentId, {DateTime? week}) async {
    weekCalls.add(studentId);
    return _week(studentId, present: studentId == 'a' ? 3 : 5);
  }
}

class _Gate implements NotificationPermissionGate {
  bool enabled = false;
  @override
  Future<bool> isEnabled() async => enabled;
  @override
  Future<bool> request() async => enabled = true;
}

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  NotificationPermissionGate? gate,
  double textScale = 1,
}) async {
  final c = ParentController.instance
    ..familyRepository = repo
    ..notifications = gate
    ..noInviteBuilder = (context, onLinked) => const Text('p05-embedded');
  addTearDown(() {
    c
      ..familyRepository = null
      ..notifications = null
      ..noInviteBuilder = null;
  });
  final router = GoRouter(
    initialLocation: TeachHubRoutes.parent,
    routes: [
      ...c.routes(),
      GoRoute(
        path: TeachHubRoutes.rolePicker,
        builder: (_, _) => const Text('role-picker'),
      ),
      GoRoute(
        path: TeachHubRoutes.inviteEntry,
        builder: (_, _) => const Text('invite-entry'),
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('two children: switching loads the other child\'s week', (
    tester,
  ) async {
    final repo = _FakeRepo([_child('a', 'Minh Anh'), _child('b', 'Gia Bao')]);
    await _pump(tester, repo);

    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Gia Bao'), findsOneWidget);
    expect(find.text('Attendance this week'), findsOneWidget);
    expect(find.text('Present · 3'), findsOneWidget);

    await tester.tap(find.text('Gia Bao'));
    await tester.pumpAndSettle();
    expect(find.text('Present · 5'), findsOneWidget);
    expect(repo.weekCalls, ['a', 'b']);

    await tester.tap(find.text('Minh Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Present · 3'), findsOneWidget);
  });

  testWidgets('no linked child shows the invite entry (P05)', (tester) async {
    await _pump(tester, _FakeRepo(const []));
    expect(find.text('p05-embedded'), findsOneWidget);
    expect(find.text('Attendance this week'), findsNothing);
  });

  testWidgets('notification banner shows when off and goes away once on', (
    tester,
  ) async {
    final gate = _Gate();
    await _pump(tester, _FakeRepo([_child('a', 'Minh Anh')]), gate: gate);
    expect(find.text('Turn on notifications'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Turn on notifications'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextButton, 'Turn on notifications'),
      findsNothing,
    );
  });

  testWidgets('load failure offers retry', (tester) async {
    final repo = _FakeRepo([_child('a', 'Minh Anh')])..failStudents = true;
    await _pump(tester, repo);
    expect(find.textContaining('Could not load'), findsOneWidget);

    repo.failStudents = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Minh Anh'), findsOneWidget);
  });

  testWidgets('usable at text scale 2.0 without overflow', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      _FakeRepo([_child('a', 'Minh Anh'), _child('b', 'Gia Bao')]),
      gate: _Gate(),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Attendance this week'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Present: 3')), findsOneWidget);
    handle.dispose();
  });
}
