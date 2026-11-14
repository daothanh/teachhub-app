import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/module_health_report.dart';
import 'package:tasco_module/tasco_module.dart';

/// `ModuleManager` is built to contain a broken or over-reaching mini-app so it
/// cannot take the host down. These tests hold the other half of that bargain:
/// everything it contained has to leave the app as a signal, or a mini-app
/// disappears from the home menu with nothing to debug from.
void main() {
  ModuleManager manager() => ModuleManager();

  ModuleSlot slot(
    String id, {
    Future<void> Function()? init,
    Set<String> public = const {},
  }) {
    return ModuleSlot(
      moduleId: id,
      routePrefix: '/$id',
      notificationTypes: const {},
      init: init ?? () async {},
      routes: () => [],
      onNotification: (_, _) async {},
      dispose: () async {},
      publicRoutePrefixes: public,
    );
  }

  test('a mini-app that failed to initialize is reported', () async {
    final reasons = <String>[];
    final errors = <Object>[];
    final m = manager()
      ..register(slot('crm', init: () async => throw StateError('boom')));
    await m.initAll();

    await reportModuleHealth(
      m,
      sink: (error, _, reason) async {
        errors.add(error);
        reasons.add(reason);
      },
    );

    expect(reasons, <String>['module_init_failed:crm']);
    expect(errors.single, isA<StateError>());
  });

  test(
    'a mini-app reaching past its prefix is reported as its own signal',
    () async {
      final reasons = <String>[];
      final errors = <Object>[];
      final m = manager()..register(slot('crm', public: {'/profile'}));
      await m.initAll();

      await reportModuleHealth(
        m,
        sink: (error, _, reason) async {
          errors.add(error);
          reasons.add(reason);
        },
      );

      expect(reasons, <String>['module_contract_violation:crm']);
      expect(errors.single, isA<ModuleContractViolation>());
      expect('${errors.single}', contains('/profile'));
    },
  );

  test('a healthy startup reports nothing', () async {
    final reasons = <String>[];
    final m = manager()..register(slot('crm', public: {'/crm/help'}));
    await m.initAll();

    await reportModuleHealth(
      m,
      sink: (_, _, reason) async => reasons.add(reason),
    );

    expect(reasons, isEmpty);
  });

  test('every failing mini-app is reported, not just the first', () async {
    final reasons = <String>[];
    final m = manager()
      ..register(slot('a', init: () async => throw Exception('x')))
      ..register(slot('b', init: () async => throw Exception('y')))
      ..register(slot('c', public: {'/profile'}));
    await m.initAll();

    await reportModuleHealth(
      m,
      sink: (_, _, reason) async => reasons.add(reason),
    );

    expect(reasons, <String>[
      'module_init_failed:a',
      'module_init_failed:b',
      'module_contract_violation:c',
    ]);
  });

  test('no crash reporter (dev, or Firebase down) still completes', () async {
    final m = manager()
      ..register(slot('crm', init: () async => throw Exception('x')));
    await m.initAll();

    // Logs only — must not throw just because there is nowhere to record.
    await expectLater(reportModuleHealth(m, sink: null), completes);
  });
}
