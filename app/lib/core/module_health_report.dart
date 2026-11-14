import 'dart:developer';

import 'package:tasco_module/tasco_module.dart';

/// Where a module-health problem goes. Injected so the report can be tested
/// without a Firebase app, and so a host with a different backend can supply
/// its own.
typedef ModuleIssueSink =
    Future<void> Function(Object error, StackTrace stackTrace, String reason);

/// Surfaces what [ModuleManager] contained during startup.
///
/// The manager deliberately swallows a mini-app whose `init` throws, so one
/// broken module cannot abort host launch, and it drops any route or deep-link
/// authority a mini-app declared outside its own `routePrefix`. Both are the
/// right call — but containment without a report is silence: the mini-app just
/// disappears from the home menu with nothing in the logs and nothing in
/// Crashlytics, and "why did the CRM tile vanish?" has no answer.
///
/// Init failures are errors. Contract violations are security signals — a
/// mini-app reaching past its own prefix is worth looking at even though the
/// declaration was already refused.
Future<void> reportModuleHealth(
  ModuleManager manager, {
  ModuleIssueSink? sink,
}) async {
  for (final failure in manager.initFailures) {
    log(
      'Mini-app "${failure.moduleId}" failed to initialize',
      name: 'bootstrap',
      error: failure.error,
      stackTrace: failure.stackTrace,
    );
    await sink?.call(
      failure.error,
      failure.stackTrace,
      'module_init_failed:${failure.moduleId}',
    );
  }

  for (final violation in manager.contractViolations) {
    log('$violation', name: 'bootstrap');
    await sink?.call(
      violation,
      StackTrace.current,
      'module_contract_violation:${violation.moduleId}',
    );
  }
}
